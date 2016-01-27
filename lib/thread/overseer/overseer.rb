module BBLib

  class Overseer
    attr_reader :max_threads, :stashed, :message_queue, :last_id, :max_extension
    attr_reader :processor, :queue_manager, :queue, :ready, :running, :done
    attr_reader :elevation_policy, :sleep_policy, :retention

    def initialize max: nil, start:false, retention:nil, proc_sleep:0, queue_sleep:0
      @last_id, @max_extension = -1, 0
      @queue, @ready, @running, @done = [], [], [], []
      self.max = max
      self.retention = retention
      @message_queue = BBLib::MessageQueue.new
      @threads, @stashed = Hash.new, Hash.new
      @elevation_policy = { 0 => nil, 1 => 60, 2 => 30, 3 => 30, 4 => 60, 5 => 120, 6 => nil }
      @sleep_policy = { process:proc_sleep, queue:queue_sleep }
      if start then self.start end
    end

    def queue block, args = [], name:nil, priority:3, start_at: nil, max_life:nil, count:true, depend_on:nil
      if @stashed.include?(block) then block = @stashed[block] end
      raise "Self referencing dependencies are not allowed. #{depend_on} == #{@last_id+1} || #{name}" if !depend_on.nil? && (depend_on.is_a?(Array) && depend_on.include?(@last_id+1) || depend_on == @last_id+1 || depend_on == name)
      raise "Invalid type exception. Got #{block.class} but expected Proc" unless Proc === block
      @queue << ({ id:next_id, count:count, state: :queued, proc:block, depend_on:depend_on, args:args, queued:Time.now.to_f, added:nil, last_elev:Time.now.to_f, started:nil, max_life:max_life, name:name, priority:BBLib::keep_between(priority.to_i, 0, 6), start_at:start_at, initial_priority:BBLib::keep_between(priority.to_i, 0, 6) })
      @last_id
    end

    def stash name, block
      raise "Invalid argument type #{block.class}. Expected Proc" unless block.is_a? Proc
      @stashed[name] = block
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
      matches.map{ |r| [r[:id], r[:thread] ? r[:thread].value : nil]}.to_h
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
      @message_queue.start
      start_queue_manager
      start_processor
      running?
    end

    def stop
      @message_queue.stop
      @queue_manager.kill unless @queue_manager.nil?
      @processor.kill unless @processor.nil?
      sleep(0.3)
      !running?
    end

    def retention= r
      @retention = r.nil? ? nil : BBLib::keep_between(r, 0, nil)
    end

    def set_elevation_policy num, time
      return nil unless Fixnum === num && num.between?(1, 5) && (time.nil? || Fixnum === time && time > 0)
      @elevation_policy[num] = time
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

      def next_id
        @last_id+=1
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
              item[:thread] = Thread.new{
                begin
                  item[:proc].call(item[:args], {mq:@message_queue, tinfo:item.reject{ |k, v| [:args, :thread, :proc, :dependency_info].include? k }, dinfo:item[:dependency_info]})
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
              dependency_check = q[:depend_on].nil?
              if !dependency_check
                deps = state_of(q[:depend_on])
                if deps.empty?
                  if q[:id] == 1 then puts 'missing' end
                  q[:state] = :missing_dependencies
                  @done << @queue.delete(q)
                elsif deps.any?{ |k,v| [:missing_dependencies, :canceled, :error, :failed_dependancy].include? v }
                  if q[:id] == 1 then puts 'failed' end
                  q[:state] = :failed_dependancy
                  @done << @queue.delete(q)
                elsif deps.any?{ |k,v| v != :finished }
                  if q[:id] == 1 then puts 'waiting'; p deps end
                  q[:state] = :waiting
                else
                  if q[:id] == 1 then puts 'GO' end
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
                r[:finished] = Time.now.to_f
                r[:state] = r[:thread].value.is_a?(Exception) ? :error : :finished unless r[:state] == :killed
                if !r[:count] then @max_extension-=1 end
                @done.push @running.delete_at(index)
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
