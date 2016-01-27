module BBLib

  class Overseer
    attr_reader :max_threads, :stashed, :message_queue, :last_id, :max_extension
    attr_reader :processor, :queue_manager, :queue, :ready, :running, :done
    attr_reader :elevation_policy, :sleep_policy, :retention, :message_queues

    def initialize max: nil, start:false, retention:nil, proc_sleep:0, queue_sleep:0
      @last_id, @max_extension = -1, 0
      @queue, @ready, @running, @done = [], [], [], []
      self.max = max
      self.retention = retention
      @message_queues = Hash.new
      add_message_queue :default, BBLib::MessageQueue.new
      @threads, @stashed = Hash.new, Hash.new
      @elevation_policy = { 0 => nil, 1 => 60, 2 => 30, 3 => 30, 4 => 60, 5 => 120, 6 => nil }
      @sleep_policy = { process:proc_sleep, queue:queue_sleep }
      if start then self.start end
    end

    TASK_TYPES = [ :proc, :lambda, :script, :cmd ]

    def queue task = nil, args = [], type: :proc, message_queue: :default, repeat:false, name:nil, priority:3, start_at: nil, max_life:nil, count:true, dependencies:nil
      return @queue unless task
      raise "Invalid type #{type}. Options are #{TASK_TYPES}." unless TASK_TYPES.include?(type)
      raise "Self referencing dependencies are not allowed. #{dependencies} cannot include #{@last_id+1} OR '#{name}'" if !dependencies.nil? && (dependencies.is_a?(Array) && dependencies.include?(@last_id+1) || dependencies == @last_id+1 || dependencies == name)
      if @stashed.include?(task) then type = @stashed[task][:type]; task = @stashed[task][:task] end
      case type
      when :proc || :block || :lambda
        raise "Invalid type. Got #{block.class} but expected Proc" unless Proc === task || Lambda === task
      when :script
        task = construct_script task
      when :cmd
        task = construct_cmd task
      end
      @queue << ({ id:next_id,
        count:count,
        type:type,
        state: :queued,
        proc:task,
        dependencies:dependencies,
        args:args,
        queued:Time.now.to_f,
        added:nil,
        last_elev:Time.now.to_f,
        started:nil,
        max_life:max_life,
        name:name,
        repeat:repeat,
        run_count:0,
        message_queue:message_queue,
        priority:BBLib::keep_between(priority.to_i, 0, 6),
        start_at: (start_at.is_a?(Numeric) ? Time.now + start_at : (Time === start_at ? start_at : nil)),
        initial_priority:BBLib::keep_between(priority.to_i, 0, 6) })
      @last_id
    end

    def queue_script path, args = [], repeat:false, name:nil, priority:3, start_at: nil, max_life:nil, count:true, dependencies:nil
      construct_script path
    end

    def stash name, task, type = :proc
      # raise "Invalid argument type #{block.class}. Expected Proc" unless task.is_a? Proc
      @stashed[name.to_s.to_clean_sym] = {task:task, type:type}
    end

    def max= m
      @max = m.nil? ? nil : BBLib::keep_between(m, 1, nil)
    end

    def active? name
      return @threads[name].any?{ |t| t.alive? }
    end

    def state_of id
      retrieve(id).map{ |r| [r[:id], r[:state]]}.to_h.sort.to_h
    end

    # Returns a key-value hash with the result of each thread.
    # Results are only returned if they have a status code of :finished
    def value_of id
      matches = @done.find_all{ |d| d[:state] == :finished && (d[:id] == id || d[:name] == id) }
      matches.map{ |r| [r[:id], (r[:thread] ? r[:thread].value : nil)]}.to_h
    end

    # ID can be the exact Fixnum id of a job or the arbitrary name
    def retrieve id
      results = []
      [@queue, @ready, @running, @done].flatten.each do |item|
        if item && item[:name] == id || item[:id] == id || (id.is_a?(Array) && (id.include?(item[:name]) || id.include?(item[:id]) ) )
          results << item
        end
      end
      results.sort_by{ |v| v[:id] }
    end

    def cancel id
      success = []
      retrieve(id).each do |r|
        changed = true
        case r[:state]
        when :queued, :ready, :running
          [@queue, @running, @ready].each do |queue|
            index = 0
            queue.each do |q|
              if q == r
                @done << queue.delete(r)
                if r[:thread] then r[:thread].kill end
              else
                index+=1
              end
            end
          end
        else
          changed = false
        end
        if changed then r[:state] = :canceled; success << r[:id] end
      end
      success
    end

    def start
      @message_queues.each{ |n,m| m.start }
      start_queue_manager
      start_processor
      running?
    end

    def stop
      @queue_manager.kill unless @queue_manager.nil?
      @processor.kill unless @processor.nil?
      sleep(0.3)
      @message_queues.each{ |n,m| m.stop }
      !running?
    end

    def restart
      start
      stop
    end

    def retention= r
      @retention = r.nil? ? nil : BBLib::keep_between(r, 0, nil)
    end

    def set_elevation_policy num, time
      return nil unless Fixnum === num && num.between?(1, 5) && (time.nil? || Fixnum === time && time > 0)
      @elevation_policy[num] = time
    end

    def set_sleep_policy type, time
      return nil unless @sleep_policy.include?(type) && Numeric === time
      @sleep_policy[type] = BBLib::keep_between(time, 0, nil)
    end

    def add_message_queue name, mq
      raise "Invalid message queue: #{mq} (#{mq.class})" unless mq.is_a?(BBLib::MessageQueue)
      @message_queues[name.to_s.to_clean_sym] = mq
      mq.restart
      name.to_clean_sym
    end

    def remove_message_queue name
      @message_queues.delete(name.to_s.to_clean_sym) unless name.to_s.to_clean_sym == :default
    end

    def running?
      return @queue_manager.alive? && @processor.alive?
    end

    def finished?
      return @queue.empty? && @ready.empty? && @running.empty?
    end

    def clear
      @done.clear
    end

    def flush
      @done.clear
      @queue.clear
      @ready.clear
      @running.each{ |r| r[:thread].kill }
      @running.clear
    end

    private

      def construct_script path
        raise "Path to script is invalid: #{path}" unless File.exists?(path)
        construct_cmd "#{Gem.ruby.include?(' ') ? "\"#{Gem.ruby}\"" : Gem.ruby} #{path.include?(' ') ? "\"#{path}\"" : path}"
      end

      def construct_cmd cmd
        proc{ |*args, mq:nil, tinfo:tinfo, dinfo:dinfo|
          p = IO.popen("#{cmd} #{args.map{|a| a.include?(' ') ? "\"#{a}\"" : a}.join(' ')}")
          results = []
          while !p.eof?
            line = p.readline
            mq.push '*'*25
            mq.push line
            results.push line
          end
          results
        }
      end

      def next_id
        @last_id+=1
      end

      def parse_repeat item
        rep = (item[:repeat] == true || item[:repeat].is_a?(Numeric) && item[:repeat].to_i > item[:run_count] || item[:repeat].is_a?(Time) && Time.now < item[:repeat] || item[:repeat].is_a?(String) && (item[:repeat].start_with?('after:') || item[:repeat].start_with?('every:')))
        if rep && item[:repeat].is_a?(String)
          if item[:repeat].start_with?('every:')
            item[:start_at] = Time.at(item[:started] + item[:repeat].parse_duration(output: :sec))
          else
            item[:start_at] = Time.now + item[:repeat].parse_duration(output: :sec)
          end
        end
        # if item[:start_at] && item[:start_at] < Time.now.to_f
        #   item[:state] = :ready
        # else
          item[:state] = :queued
        # end
        item[:priority] = item[:initial_priority]
        rep
      end

      def start_processor
        @processor = Thread.new {
          loop do
            item = nil
            # Check for priority 0s or threads that don't count towads the max
            item = @ready.find{ |r| r[:priority] == 0 || !r[:count] }
            if item then @ready.delete(item) end
            # It no 0 or count:false items were found, add the next item from the queue
            if item.nil? && (@max.nil? || (@running.size < @max + @max_extension)) && !@ready.empty?
              item = @ready.shift
            end
            # If an item is set, then it is started.
            if !item.nil?
              item[:started] = Time.now.to_f
              item[:state] = :running
              item[:run_count] = item[:run_count] + 1
              message_queue = @message_queues[item[:message_queue]] ||= @message_queues[:default]
              args = {mq:message_queue, tinfo:item.reject{ |k, v| [:args, :thread, :proc, :dependency_info].include? k }, dinfo:item[:dependency_info]}
              params = item[:proc].parameters.map{ |o, t| t }
              args.keys.each do |k|
                if !params.include?(k) then args.delete(k) end
              end
              item[:thread] = Thread.new{
                begin
                  item[:proc].call(item[:args], args)
                rescue StandardError => e
                  e
                end
              }
              @running << item
              # If the item shouldn't count towards the max threads running, the extension number is incremented
              if !item[:count] then @max_extension+=1 end
            end
            sleep(@sleep_policy[:process])
          end
        }
      end

      def start_queue_manager
        @queue_manager = Thread.new {
          loop do
            # Check to ensure max_extension hasn't dipped below 0 for any reason
            if @max_extension < 0 then @max_extension = 0 end
            # Process incoming queue first
            @queue.sort_by!{|v| [v[:p], v[:queued]]}
            index = 0
            @queue.each do |q|
              start_ready = q[:start_at].nil? || Time.now.to_f >= q[:start_at].to_f
              # Check for dependent threads.
              dependency_check = q[:dependencies].nil?
              if !dependency_check
                deps = state_of(q[:dependencies])
                if deps.empty?
                  q[:state] = :missing_dependencies
                  @done << @queue.delete(q)
                elsif deps.any?{ |k,v| [:missing_dependencies, :canceled, :error, :failed_dependancy].include? v }
                  q[:state] = :failed_dependancy
                  @done << @queue.delete(q)
                elsif deps.any?{ |k,v| v != :finished }
                  q[:state] = :waiting
                else
                  dependency_check = true
                  q[:dependency_info] = []
                  deps.each{ |k,v| q[:dependency_info] << retrieve(k).first[:thread].value }
                end
              end
              # Add items to the ready queue if there is no start time, or it is or is past the start time and any dependcies have finished
              if start_ready && dependency_check
                q[:added] = Time.now.to_f
                q[:state] = :ready
                @ready << @queue.delete(q)
              else
                index+=1
              end
            end

            # Check for elevation in ready queue
            @ready.each do |i|
              next unless @elevation_policy[i[:priority]]
              if Time.now.to_f - i[:last_elev] >= @elevation_policy[i[:priority]]
                i[:priority] = i[:priority] - 1
                i[:last_elev] = Time.now.to_f
              end
            end

            # Resort the ready queue
            @ready.sort_by!{ |r| [r[:priority], r[:added]] }

            #Check the running queue for finished threads or threads that need to be killed
            index = 0
            @running.each do |r|
              # Kill any threads that are alive, have a max life and have over shot their max life
              if r[:thread].alive? && r[:max_life] && Time.now.to_f - r[:started] > r[:max_life]
                r[:thread].kill
                r[:state] = :killed
              end
              # Move any dead threads to the done queue to clear up space for new threads to run
              if !r[:thread].alive?
                r.delete :mq
                if !r[:count] then @max_extension-=1 end
                if parse_repeat(r)
                  @queue.push @running.delete_at(index)
                else
                  r[:finished] = Time.now.to_f
                  r[:state] = r[:thread].value.is_a?(Exception) ? :error : :finished unless r[:state] == :killed
                  @done.push @running.delete_at(index)
                end
              end
              index+=1
            end

            # Clean up the done queue
            if @retention
              while @done.size > @retention
                @done.shift
              end
            end

            sleep(@sleep_policy[:queue])
          end
        }
      end

  end

end
