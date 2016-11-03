# frozen_string_literal: true
module BBLib
  class Cron < BBLib::LazyClass
    attr_str :expression, default: '* * * * * *'
    attr_reader :parts, :time

    def next(exp = @expression, count: 1, time: Time.now)
      expression = exp unless exp == @expression
      closest(count: count, time: time, direction: 1)
    end

    def prev(exp = @expression, count: 1, time: Time.now)
      expression = exp unless exp == @expression
      closest(count: count, time: time, direction: -1)
    end

    def expression=(e)
      e = e.to_s.downcase
      SPECIAL_EXP.each { |x, v| e = x if v.include?(e) }
      @expression = e
      parse
    end

    def self.next(exp, count: 1, time: Time.now)
      BBLib::Cron.new(expression: exp).next(count: count, time: time)
    end

    def self.prev(exp, count: 1, time: Time.now)
      BBLib::Cron.new(expression: exp).prev(count: count, time: time)
    end

    def self.valid?(exp)
      !(numeralize(exp) =~ /\A(.*?\s){4,5}.*?\S\z/).nil?
    end

    def valid?(exp)
      BBLib::Cron.valid?(exp)
    end

    def self.numeralize(exp)
      REPLACE.each do |k, v|
        v.each do |r|
          exp = exp.to_s.gsub(r.to_s, k.to_s)
        end
      end
      exp
    end

    def time_match?(time)
      (@parts[:minute].empty? || @parts[:minute].include?(time.min)) &&
      (@parts[:hour].empty? || @parts[:hour].include?(time.hour)) &&
      (@parts[:day].empty? || @parts[:day].include?(time.day)) &&
      (@parts[:weekday].empty? || @parts[:weekday].include?(time.wday)) &&
      (@parts[:month].empty? || @parts[:month].include?(time.month)) &&
      (@parts[:year].empty? || @parts[:year].include?(time.year))
    end

    private

    def lazy_init(*args)
      self.expression = args.first if args.first.is_a?(String)
    end

    def parse
      @parts = {}
      PARTS.keys.zip(@expression.split(' ')).to_h.each do |part, piece|
        info = PARTS[part]
        @parts[part] = parse_cron_numbers(piece, info[:min], info[:max], Time.now.send(info[:send]))
      end
    end

    def parse_cron_numbers(exp, min, max, qmark)
      numbers = []
      return numbers if exp == '*'
      exp = Cron.numeralize(exp).gsub('?', qmark.to_s).gsub('*', "#{min}-#{max}")
      exp.scan(/\*\/\d+|\d+\/\d+|\d+-\d+\/\d+/).each do |s|
        range = s.split('/').first.split('-').map(&:to_i) + [max]
        divisor = s.split('/').last.to_i
        Range.new(*range[0..1]).each_with_index do |i, index|
          numbers.push(i) if index.zero? || (index % divisor).zero?
        end
        exp = exp.sub(s, '')
      end
      exp.scan(/\d+\-\d+/).each do |e|
        nums = e.scan(/\d+/).map(&:to_i)
        numbers.push(Range.new(*nums).to_a)
      end
      numbers.push(exp.scan(/\d+/).map(&:to_i))
      numbers.flatten.uniq.sort.reject { |r| r < min || r > max }
    end

    def closest(direction: 1, count: 1, time: Time.now)
      return unless @expression
      results = (1..count).flat_map do |_i|
        time = next_time(time + 60 * direction, direction)
      end
      count <= 1 ? results.first : results.compact
    end

    def next_time(time, direction)
      original = time.dup
      safety = 0
      methods = [:next_min, :next_hour, :next_day, :next_weekday, :next_month, :next_year]
      methods = methods.reverse if direction.positive?
      until safety >= 1_000_000 || time_match?(time)
        methods.each do |sym|
          time = send(sym, time, direction)
        end
        safety += 1
      end
      time - (time.sec.zero? ? 0 : original.sec)
    end

    def next_min(time, direction)
      return time if @parts[:minute].empty?
      time += 60 * direction until @parts[:minute].include?(time.min)
      time
    end

    def next_hour(time, direction)
      return time if @parts[:hour].empty?
      until @parts[:hour].include?(time.hour)
        time -= time.min * 60 if direction.positive?
        time += (59 - time.min) * 60 if direction.negative?
        time += 60*60 * direction
      end
      time
    end

    def next_day(time, direction)
      return time if @parts[:day].empty?
      until @parts[:day].include?(time.day)
        time += 24*60*60 * direction
      end
      time
    end

    def next_weekday(time, direction)
      return time if @parts[:weekday].empty?
      time += 24*60*60 * direction until @parts[:weekday].include?(time.wday)
      time
    end

    def next_month(time, direction)
      return time if @parts[:month].empty?
      until @parts[:month].include?(time.month)
        original = time.month
        min      = direction.positive? ? 0 : 59
        hour     = direction.positive? ? 0 : 23
        day      = direction.positive? ? 1 : 31
        month = BBLib.loop_between(time.month + direction, 1, 12)
        year  = if direction.positive? && month == 1
                  time.year + 1
                elsif direction.negative? && month == 12
                  time.year - 1
                else
                  time.year
                end
        time  = Time.new(year, month, day, hour, min)
        if direction.negative? && time.month == original
          time -= 24 * 60 * 60 while time.month == original
        end
      end
      time
    end

    def next_year(time, direction)
      return time if @parts[:year].empty?
      until @parts[:year].include?(time.year)
        day   = direction.positive? ? 1 : 31
        hour  = direction.positive? ? 0 : 23
        min   = direction.positive? ? 0 : 59
        month = direction.positive? ? 1 : 12
        time  = Time.new(time.year + direction, month, day, hour, min)
      end
      time
    end

    PARTS = {
      minute:  { send: :min, min: 0, max: 59, size: 60 },
      hour:    { send: :hour, min: 0, max: 23, size: 60*60 },
      day:     { send: :day, min: 1, max: 31, size: 60*60*24 },
      month:   { send: :month, min: 1, max: 12 },
      weekday: { send: :wday, min: 0, max: 6 },
      year:    { send: :year, min: 0, max: 3_000 }
    }.freeze

    REPLACE = {
      0  => [:sunday, :sun],
      1  => [:monday, :mon, :january, :jan],
      2  => [:tuesday, :tues, :february, :feb],
      3  => [:wednesday, :wednes, :tue, :march, :mar],
      4  => [:thursday, :thurs, :wed, :april, :apr],
      5  => [:friday, :fri, :thu, :may],
      6  => [:saturday, :sat, :june, :jun],
      7  => [:july, :jul],
      8  => [:august, :aug],
      9  => [:september, :sept, :sep],
      10 => [:october, :oct],
      11 => [:november, :nov],
      12 => [:december, :dec]
    }.freeze

    SPECIAL_EXP = {
      '0 0 * * * *'  => ['@daily', '@midnight', 'daily', 'midnight'],
      '0 12 * * * *' => ['@noon', 'noon'],
      '0 0 * * 0 *'  => ['@weekly', 'weekly'],
      '0 0 1 * * *'  => ['@monthly', 'monthly'],
      '0 0 1 1 * *'  => ['@yearly', '@annually', 'yearly', 'annually'],
      '? ? ? ? ? ?'  => ['@reboot', '@restart', 'reboot', 'restart']
    }.freeze
  end
end
