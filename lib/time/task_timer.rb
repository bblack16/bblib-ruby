module BBLib

  class TaskTimer
    attr_reader :tasks, :save, :retention

    def initialize task:nil, retention:100
      @tasks = {}
      self.retention = retention
      if task then start task end
    end

    def retention= num
      @retention = num.nil? ? nil : BBLib.keep_between(num, -1, nil)
    end

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

    def save= save
      @save = save
    end

    def active? task
      return false unless @tasks.keys.include? task
      !@tasks[task][:current].nil?
    end

    def method_missing *args
      temp = args.first.to_s.sub('p_','').to_sym
      type, task = TIMER_TYPES.keys.find{ |k| k == temp || TIMER_TYPES[k].include?(temp) }, args[1] ||= :default
      raise NoMethodError unless type
      t = time task, type
      args.first.to_s.start_with?('p_') && type != :count ? t.to_duration : t
    end

    private

      TIMER_TYPES = {
        current: [],
        avg: [:average, :av],
        all: [:times],
        max: [:maximum, :largest],
        min: [:minimum, :smallest],
        sum: [],
        last: [:latest],
        first: [:initial],
        count: [:total]
      }

  end

end
