module BBLib

  class MyCron
    attr_reader :exp, :parts, :time

    def initialize exp
      @parts = Hash.new
      self.exp = exp
    end

    def closest exp = @exp, direction:1, count: 1, time: Time.now
      if exp then self.exp = exp end
      results = []
      (1..count).each{ |i| results.push next_time(i == 1 ? time : results.last, direction) }
      count <= 1 ? results.first : results.reject{ |r| r.nil? }
    end

    def next exp = @exp, count: 1, time: Time.now
      closest exp, count:count, time:time, direction:1
    end

    def prev exp = @exp, count: 1, time: Time.now
      closest exp, count:count, time:time, direction:-1
    end

    def exp= e
      @exp = e
      parse
    end

    def self.next exp, count: 1, time: Time.now
      t = BBLib::MyCron.new(exp).next(count:count, time:time)
    end

    def self.prev exp, count: 1, time: Time.now
      BBLib::MyCron.new(exp).prev(count:count, time:time)
    end

    def self.valid? exp
      !(numeralize(exp) =~ /\A(.*?\s){5}.*?\S\z/).nil?
    end

    private

      def parse
        pieces = @exp.split(' ')
        (0..pieces.size-1).each do |i|
          interval = PARTS.keys[i]
          @parts[interval] = parse_cron_numbers(pieces[i], PARTS[interval][:min], PARTS[interval][:max])
        end
        @parts[:weekday] = @parts[:weekday].map{ |v| v - 1 }
      end

      def self.numeralize exp
        exp = exp.to_s.downcase
        REPLACE.each do |k, v|
          v.each do |r|
            exp.gsub!(r.to_s, k.to_s)
          end
        end
        exp
      end

      def parse_cron_numbers exp, min, max
        numbers = Array.new
        exp = MyCron.numeralize(exp)
        numbers.push exp.scan(/\d+/).map{ |m| m.to_i }
        exp.strip.scan(/\d+\-\d+/).each do |e|
          nums = e.scan(/\d+/).map{ |n| n.to_i }
          numbers.push (nums.min..nums.max).map{ |n| n }
        end
        numbers.flatten!.sort!
        numbers.uniq.reject{ |r| r < min || r > max }
      end

      def next_day time, direction
        return nil unless time
        weekdays, days, months, years = @parts[:weekday], @parts[:day], @parts[:month], @parts[:year]
        date, safety = nil, 0
        while date.nil? && safety < 50000
          if (days.empty? || days.include?(time.day)) && (months.empty? || months.include?(time.month)) && (years.empty? || years.include?(time.year)) && (weekdays.empty? || weekdays.include?(time.wday))
            date = time
          else
            time+= 24*60*60*direction
            # time = Time.new(time.year, time.month, time.day, 0, 0)
          end
          safety+=1
        end
        return nil if safety == 50000
        time
      end

      def next_time time, direction
        orig, fw = time.to_f, (direction == 1)
        current = next_day(time, direction)
        return nil unless current
        if (fw ? current.to_f > orig : current.to_f < orig)
          current = Time.new(current.year, current.month, current.day, (fw ? 0 : 23), (fw ? 0 : 59))
        else
          current+= (fw ? 60 : -60)
        end
        while !@parts[:day].empty? && !@parts[:day].include?(current.day) || !@parts[:hour].empty? && !@parts[:hour].include?(current.hour) || !@parts[:minute].empty? && !@parts[:minute].include?(current.min)
          day = [current.day, current.month, current.year]
          current+= (fw ? 60 : -60)
          if day != [current.day, current.month, current.year] then current = next_day(current, direction) end
          return nil unless current
        end
        current - current.sec
      end

      PARTS = {
        minute: {send: :min, min:0, max:59, size: 60},
        hour: {send: :hour, min:0, max:23, size: 60*60},
        day: {send: :day, min:1, max:31, size: 60*60*24},
        month: {send: :month, min:1, max:12},
        weekday: {send: :wday, min:1, max:7},
        year: {send: :year, min:0, max:90000}
      }

      REPLACE = {
        1 => [:sunday, :sun, :january, :jan],
        2 => [:monday, :mon, :february, :feb],
        3 => [:tuesday, :tues, :tue, :march, :mar],
        4 => [:wednesday, :wednes, :wed, :april, :apr],
        5 => [:thursday, :thurs, :thu, :may],
        6 => [:friday, :fri, :june, :jun],
        7 => [:saturday, :sat, :july, :jul],
        8 => [:august, :aug],
        9 => [:september, :sept, :sep],
        10 => [:october, :oct],
        11 => [:november, :nov],
        12 => [:december, :dec]
      }

  end

end
