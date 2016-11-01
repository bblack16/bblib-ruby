# frozen_string_literal: true
module BBLib
  class TaskTimer < LazyClass
    attr_hash :tasks, default: {}
    attr_int_between -1, nil, :retention, default: 100

    def time(task = :default, type = :current)
      return nil unless @tasks.keys.include? task
      numbers = @tasks[task][:history].map { |v| v[:time] }
      case type
      when :current
        return nil unless @tasks[task][:current]
        return Time.now.to_f - @tasks[task][:current]
      when :min
        return numbers.min
      when :max
        return numbers.max
      when :avg
        return numbers.inject { |sum, n| sum + n }.to_f / numbers.size
      when :sum
        return numbers.inject { |sum, n| sum + n }
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

    def clear(task)
      return nil unless @tasks.keys.include?(task)
      stop task
      @tasks[task][:history].clear
    end

    def start(task = :default)
      @tasks[task] = { history: [], current: nil } unless @tasks.keys.include?(task)
      stop task if @tasks[task][:current]
      @tasks[task][:current] = Time.now.to_f
      0
    end

    def stop(task = :default)
      return nil unless @tasks.keys.include?(task) && active?(task)
      time_taken = Time.now.to_f - @tasks[task][:current].to_f
      @tasks[task][:history] << { start: @tasks[task][:current], stop: Time.now.to_f, time: time_taken }
      @tasks[task][:current] = nil
      if @retention && @tasks[task][:history].size > @retention then @tasks[task][:history].shift end
      time_taken
    end

    def restart(task = :default)
      start(task) unless stop(task).nil?
    end

    def active?(task)
      return false unless @tasks.keys.include? task
      !@tasks[task][:current].nil?
    end

    def stats(task, pretty: false)
      return nil unless @tasks.include?(task)
      TIMER_TYPES.map do |k, _v|
        next if STATS_IGNORE.include?(k)
        [k, send(k, task, pretty: pretty)]
      end.compact.to_h
    end

    def method_missing(*args, **named)
      temp   = args.first.to_sym
      pretty = named.delete :pretty
      type   = TIMER_TYPES.keys.find { |k| k == temp || TIMER_TYPES[k].include?(temp) }
      task   = args[1] ||= :default
      return super unless type
      t = time task, type
      pretty && type != :count && t ? (t.is_a?(Array) ? t.map(&:to_duration) : t.to_duration) : t
    end

    def respond_to_missing?(method, include_private = false)
      TIMER_TYPES.keys.find { |k| k == method || TIMER_TYPES[k].include?(method) } || super
    end

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
    }.freeze

    private

    STATS_IGNORE = [:current, :all].freeze

    def lazy_init(*args)
      start(args.first) if args.first.is_a?(Symbol)
    end
  end
end
