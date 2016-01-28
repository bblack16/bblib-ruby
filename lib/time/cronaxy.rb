module BBLib

  class Cronaxy
    attr_reader :exp, :parts, :time

    def initialize exp
      @parts = Hash.new
      self.exp = exp
    end

    def next exp = @exp, count: 1, time: Time.now
      if exp then self.exp = exp end
      results = []
      (1..count).each{ |i| results.push next_time(i == 1 ? time : results.last) }
      count <= 1 ? results.first : results
    end

    def exp= e
      @exp = e
      parse
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

      def parse_cron_numbers exp, min, max
        numbers = Array.new
        numbers.push exp.scan(/\d+/).map{ |m| m.to_i }
        exp.strip.scan(/\d+\-\d+/).each do |e|
          nums = e.scan(/\d+/).map{ |n| n.to_i }
          numbers.push (nums.min..nums.max).map{ |n| n }
        end
        numbers.flatten!.sort!
        numbers.uniq.reject{ |r| r < min || r > max }
      end

      def next_day time
        weekdays = @parts[:weekday]
        days = @parts[:day]
        months = @parts[:month]
        years = @parts[:year]
        date, safety = nil, 0
        while date.nil? && safety < 10000
          if (days.empty? || days.include?(time.day)) && (months.empty? || months.include?(time.month)) && (years.empty? || years.include?(time.year)) && (weekdays.empty? || weekdays.include?(time.wday))
            date = time
          else
            time = time + 24*60*60
          end
          safety+=1
        end
        time
      end

      def next_time time
        orig = time.to_f
        current = next_day(time)
        if orig < current.to_f
          target = @parts[:hour].min
          target = 0 unless target
          while current.hour != target
            current = current - 60*60
          end
          target = @parts[:minute].min
          target = 0 unless target
          while current.min != target
            current = current - 60
          end
        else
          if @parts[:minute].empty?
            target = current.min + 1
          elsif current.min >= @parts[:minute].max
            target = @parts[:minute].min
          else
            target = @parts[:minute].find{ |m| m > current.min }
          end
          while current.min != target
            current = current + 60
          end
          if @parts[:hour].empty?
            target = current.hour
          elsif current.hour >= @parts[:hour].max
            target = @parts[:hour].min
          else
            target = @parts[:hour].find{ |m| m > current.hour }
          end
          while current.hour != target
            current = current + 60*60
          end
        end
        current - current.sec
      end

      PARTS = {
        minute: {min:0, max:59},
        hour: {min:0, max:23},
        day: {min:1, max:31},
        month: {min:1, max:12},
        weekday: {min:1, max:7},
        year: {min:0, max:90000}
      }

  end

end
