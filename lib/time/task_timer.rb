module BBLib
  # Simple timer that can track tasks based on time. Also provides aggregated metrics
  #  and history for each task run. Generally useful for benchmarking or logging.
  #
  # @author Brandon Black
  # @attr [Hash] tasks The information on all running tasks and history of all tasks up to the retention.
  # @attr [Integer] retention The number of runs to collect per task before truncation.
  class TaskTimer
    include Effortless
    attr_hash :tasks, default: {}, serialize: false
    attr_int_between -1, nil, :retention, default: 100

    # Returns an aggregated metric for a given type.
    #
    # @param [Symbol] task The key value of the task to retrieve
    # @param [Symbol] type The metric to return.
    #   Options are :avg, :min, :max, :first, :last, :sum, :all and :count.
    # @return [Float, Integer, Array] Returns either the aggregation (Numeric) or an Array in the case of :all.
    def time(task = :default, type = :current)
      return nil unless tasks.keys.include?(task)
      numbers = tasks[task][:history].map { |v| v[:time] }
      case type
      when :current
        return nil unless tasks[task][:current]
        Time.now.to_f - tasks[task][:current]
      when :min, :max, :first, :last
        numbers.send(type)
      when :avg
        numbers.size.zero? ? nil : numbers.inject { |sum, n| sum + n }.to_f / numbers.size
      when :sum
        numbers.inject { |sum, n| sum + n }
      when :all
        numbers
      when :count
        numbers.size
      end
    end

    # Removes all history for a given task
    #
    # @param [Symbol] task The name of the task to clear history from.
    # @return [NilClass] Returns nil
    def clear(task = :default)
      return nil unless tasks.keys.include?(task)
      stop task
      tasks[task][:history].clear
    end

    # Start a new timer for the referenced task. If a timer is already running for that task it will be stopped first.
    #
    # @param [Symbol] task The name of the task to start.
    # @return [Integer] Returns 0
    def start(task = :default)
      tasks[task] = { history: [], current: nil } unless tasks.keys.include?(task)
      stop task if tasks[task][:current]
      tasks[task][:current] = Time.now.to_f
      0
    end

    # Stop the referenced timer.
    #
    # @param [Symbol] task The name of the task to stop.
    # @return [Float, NilClass] The amount of time the task had been running or nil if no matching task was found.
    def stop(task = :default)
      return nil unless tasks.keys.include?(task) && active?(task)
      time_taken = Time.now.to_f - tasks[task][:current].to_f
      tasks[task][:history] << { start: tasks[task][:current], stop: Time.now.to_f, time: time_taken }
      tasks[task][:current] = nil
      if retention && tasks[task][:history].size > retention then tasks[task][:history].shift end
      time_taken
    end

    def restart(task = :default)
      start(task) unless stop(task).nil?
    end

    def active?(task = :default)
      return false unless tasks.keys.include?(task)
      !tasks[task][:current].nil?
    end

    def stats(task = :default, pretty: false)
      return nil unless @tasks.include?(task)
      TIMER_TYPES.map do |k, _v|
        next if STATS_IGNORE.include?(k)
        [k, send(k, task, pretty: pretty)]
      end.compact.to_h
    end

    def method_missing(*args, **named)
      temp   = args.first.to_sym
      type   = TIMER_TYPES.keys.find { |k| k == temp || TIMER_TYPES[k].include?(temp) }
      return super unless type
      t = time(args[1] || :default, type)
      return t if type == :count || !named[:pretty]
      t.is_a?(Array) ? t.map(&:to_duration) : t.to_duration
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

    protected

    STATS_IGNORE = [:all].freeze

    def simple_init(*args)
      start(args.first) if args.first.is_a?(Symbol)
    end
  end
end
