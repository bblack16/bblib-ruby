module BBLib

  class TaskTimer
    attr_reader :tasks, :save

    def initialize task = nil
      @tasks = {}
      if task then start task end
    end

    def time task = :default, type = :current
      return nil unless @tasks.keys.include? task
      case type
      when :current
        return nil unless @tasks[task][:current]
        return Time.now.to_f - @tasks[task][:current]
      when :min
        return @tasks[task][:history].map{ |k, v| v[:time] }.min
      when :max
        return @tasks[task][:history].map{ |k, v| v[:time] }.max
      when :avg
        return @tasks[task][:history].map{ |k, v| v[:time] }.inject{ |sum, n| sum + n }.to_f / @tasks[task][:history].size
      when :sum
        return @tasks[task][:history].map{ |k, v| v[:time] }.inject{ |sum, n| sum + n }
      when :all
        return @tasks[task][:history].map{ |k, v| v[:time] }
      when :first
        return @tasks[task][:history].first[:time]
      when :last
        return @tasks[task][:history][@tasks[task][:history].keys.last][:time]
      end
    end

    def start task = :default
      if !@tasks.keys.include?(task) then @tasks[task] = {history: {}, current: nil} end
      if @tasks[task][:current] then stop task end
      @tasks[task][:current] = Time.now.to_f
      return 0
    end

    def stop task = :default
      return nil unless @tasks.keys.include? task
      time_taken = Time.now.to_f - @tasks[task][:current].to_f
      @tasks[task][:history][@tasks[task][:history].keys.max.to_i + 1] = {start: @tasks[task][:current], stop: Time.now.to_f, time: time_taken}
      @tasks[task][:current] = nil
      time_taken
    end

    def save= save
      @save = save
    end

    private

      TIMER_TYPES = [:current, :avg, :all, :max, :min, :sum, :last, :first ]

  end

end
