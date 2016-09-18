module BBLib

  class TaskTimer < LazyClass
    attr_hash :tasks, default: Hash.new
    attr_int_between -1, nil, :retention, default: 100

    def time task = :default, type = :current
      return nil unless @tasks.keys.include? task
      numbers = @tasks[task][:history].map{ |v| v[:time] }
      case type
      when :current
        return nil unless @tasks[task][:current]
        return Time.now.to_f - @tasks[task][:current]
      when :min
        return numbers.min
      when :max
        return numbers.max
      when :avg
        return numbers.inject{ |sum, n| sum + n }.to_f / numbers.size
      when :sum
        return numbers.inject{ |sum, n| sum + n }
      when :all
        return numbers
      when :first
        return numbers.first
      when :last
        return numbers.last
      when :count
        return numbers.size
      end
    end

    def clear task
      return nil unless @tasks.keys.include?(task)
      stop task
      @tasks[task][:history].clear
    end

    def start task = :default
      if !@tasks.keys.include?(task) then @tasks[task] = {history: [], current: nil} end
      if @tasks[task][:current] then stop task end
      @tasks[task][:current] = Time.now.to_f
      return 0
    end

    def stop task = :default
      return nil unless @tasks.keys.include?(task) && active?(task)
      time_taken = Time.now.to_f - @tasks[task][:current].to_f
      @tasks[task][:history] << {start: @tasks[task][:current], stop: Time.now.to_f, time: time_taken}
      @tasks[task][:current] = nil
      if @retention && @tasks[task][:history].size > @retention then @tasks[task][:history].shift end
      time_taken
    end

    def restart task = :default
      start(task) unless stop(task).nil?
    end

    def active? task
      return false unless @tasks.keys.include? task
      !@tasks[task][:current].nil?
    end

    def stats task, pretty: false
      return nil unless @tasks.include?(task)
      stats = "#{task}" + "\n" + '-'*30 + "\n"
      TIMER_TYPES.each do |k,v|
        next if STATS_IGNORE.include?(k)
        stats+= k.to_s.capitalize.ljust(10) + "#{self.send(k, task, pretty:pretty)}\n"
      end
      stats
    end

    def method_missing *args, **named
      temp = args.first.to_sym
      pretty = named.delete :pretty
      type, task = TIMER_TYPES.keys.find{ |k| k == temp || TIMER_TYPES[k].include?(temp) }, args[1] ||= :default
      return super unless type
      t = time task, type
      pretty && type != :count && t ? (t.is_a?(Array) ? t.map{|m| m.to_duration} : t.to_duration) : t
    end

    private

      STATS_IGNORE = [:current, :all]

      TIMER_TYPES = {
        current: [],
        count:   [:total],
        first:   [:initial],
        last:    [:latest],
        min:     [:minimum, :smallest],
        max:     [:maximum, :largest],
        avg:     [:average, :av],
        sum:     [],
        all:     [:times]
      }

      def lazy_init *args
        if args.first.is_a?(Symbol)
          start(args.first)
        end
      end

  end

end
