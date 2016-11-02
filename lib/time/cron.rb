# frozen_string_literal: true
module BBLib
  class Cron
    attr_reader :exp, :parts, :time

    def initialize(exp = '* * * * * *')
      @parts   = {}
      self.exp = exp
    end

    def closest(exp = @exp, direction: 1, count: 1, time: Time.now)
      self.exp = exp if exp
      results = []
      return results unless @exp
      (1..count).each { |i| results.push next_time(i == 1 ? time : results.last, direction) }
      count <= 1 ? results.first : results.reject(&:nil?)
    end

    def next(exp = @exp, count: 1, time: Time.now)
      closest exp, count: count, time: time, direction: 1
    end

    def prev(exp = @exp, count: 1, time: Time.now)
      closest exp, count: count, time: time, direction: -1
    end

    def exp=(e)
      SPECIAL_EXP.each { |x, v| e = x if v.include?(e) }
      @exp = e
      parse
    end

    def self.next(exp, count: 1, time: Time.now)
      BBLib::Cron.new(exp).next(count: count, time: time)
    end

    def self.prev(exp, count: 1, time: Time.now)
      BBLib::Cron.new(exp).prev(count: count, time: time)
    end

    def self.valid?(exp)
      !(numeralize(exp) =~ /\A(.*?\s){4,5}.*?\S\z/).nil?
    end

    def valid?(exp)
      BBLib::Cron.valid?(exp)
    end

    def self.numeralize(exp)
      exp = exp.to_s.downcase
      REPLACE.each do |k, v|
        v.each do |r|
          exp = exp.gsub(r.to_s, k.to_s)
        end
      end
      exp
    end

    private

    def parse
      return nil unless @exp
      pieces = @exp.split(' ')
      i = 0
      PARTS.each do |part, info|
        @parts[part] = parse_cron_numbers(pieces[i], info[:min], info[:max], Time.now.send(info[:send]))
        i+=1
      end
    end

    def parse_cron_numbers(exp, min, max, qmark)
      numbers = []
      exp     = Cron.numeralize(exp)
      exp     = exp.gsub('?', qmark.to_s)
      exp.scan(/\*\/\d+|\d+\/\d+|\d+-\d+\/\d+/).each do |s|
        range = s.split('/').first
        divisor = s.split('/').last.to_i
        range = if range == '*'
                  (min..max)
                elsif range =~ /\d+\-\d+/
                  (range.split('-').first.to_i..range.split('-').last.to_i)
                else
                  (range.to_i..max)
                end
        range.each_with_index do |i, index|
          numbers.push i if index.zero? || (index % divisor.to_i).zero?
        end
        exp = exp.sub(s, '')
      end
      numbers.push exp.scan(/\d+/).map(&:to_i)
      exp.strip.scan(/\d+\-\d+/).each do |e|
        nums = e.scan(/\d+/).map(&:to_i)
        numbers.push((nums.min..nums.max).map { |n| n })
      end
      numbers.flatten.sort.uniq.reject { |r| r < min || r > max }
    end

    def next_day(time, direction)
      return nil unless time
      weekdays = @parts[:weekday]
      days     = @parts[:day]
      months   = @parts[:month]
      years    = @parts[:year]
      date     = nil
      safety   = 0
      while date.nil? && safety < 50_000
        if (days.empty? || days.include?(time.day)) && (months.empty? || months.include?(time.month)) && (years.empty? || years.include?(time.year)) && (weekdays.empty? || weekdays.include?(time.wday))
          date = time
        else
          time+= 24*60*60*direction
          # time = Time.new(time.year, time.month, time.day, 0, 0)
        end
        safety += 1
      end
      return nil if safety == 50_000
      time
    end

    def next_time(time, direction)
      orig    = time.to_f
      fw      = (direction == 1)
      current = next_day(time, direction)
      return nil unless current
      if fw ? current.to_f > orig : current.to_f < orig
        current = Time.new(current.year, current.month, current.day, (fw ? 0 : 23), (fw ? 0 : 59))
      else
        current+= (fw ? 60 : -60)
      end
      while !@parts[:day].empty? && !@parts[:day].include?(current.day) || !@parts[:hour].empty? && !@parts[:hour].include?(current.hour) || !@parts[:minute].empty? && !@parts[:minute].include?(current.min)
        day = [current.day, current.month, current.year]
        current += (fw ? 60 : -60)
        if day != [current.day, current.month, current.year] then current = next_day(current, direction) end
        return nil unless current
      end
      current - current.sec
    end

    PARTS = {
      minute:  { send: :min, min: 0, max: 59, size: 60 },
      hour:    { send: :hour, min: 0, max: 23, size: 60*60 },
      day:     { send: :day, min: 1, max: 31, size: 60*60*24 },
      month:   { send: :month, min: 1, max: 12 },
      weekday: { send: :wday, min: 0, max: 6 },
      year:    { send: :year, min: 0, max: 90_000 }
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
