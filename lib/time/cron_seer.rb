module BBLib

  class CronSeer
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

    def previous exp = @exp, count: 1, time: Time.now
      if exp then self.exp = exp end
      results = []
      (1..count).each{ |i| results.push prev_time(i == 1 ? time : results.last) }
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

      def next_day time, direction: 1
        weekdays = @parts[:weekday]
        days = @parts[:day]
        months = @parts[:month]
        years = @parts[:year]
        date, safety = nil, 0
        while date.nil? && safety < 10000
          if (days.empty? || days.include?(time.day)) && (months.empty? || months.include?(time.month)) && (years.empty? || years.include?(time.year)) && (weekdays.empty? || weekdays.include?(time.wday))
            date = time
          else
            time = time + 24*60*60*direction
          end
          safety+=1
        end
        time
      end

      def next_time time
        orig = time.to_f
        current = next_day(time)
        safety = 0
        if orig < current.to_f
          [:hour, :minute].each do |k|
            target = @parts[k].min
            target = 0 unless target
            while current.send(PARTS[k][:send]) != target && safety < 10000
              current = current - PARTS[k][:size]
              safety+=1
            end
          end
        else
          [:hour, :minute].each do |k|
            value = current.send(PARTS[k][:send])
            if @parts[k].empty?
              target = value + (k == :minute ? 1 : 0)
            elsif value >= @parts[k].max
              target = @parts[k].min
            else
              target = @parts[k].find{ |m| m > value }
            end
            while current.send(PARTS[k][:send]) != target && safety < 10000
              current = current + PARTS[k][:size]
              safety+=1
            end
          end
        end
        current - current.sec
      end

      def prev_time time
        orig = time.to_f
        current = next_day(time, direction:-1)
        safety = 0
        if orig > current.to_f
          [:hour, :minute].each do |k|
            target = @parts[k].max
            target = PARTS[k][:max] unless target
            while current.send(PARTS[k][:send]) != target && safety < 100000
              current = current + PARTS[k][:size]
              safety+=1
            end
          end
        else
          [:hour, :minute].each do |k|
            value = current.send(PARTS[k][:send])
            if @parts[k].empty?
              target = value - (k == :minute ? 1 : 0)
            elsif value <= @parts[k].min
              target = @parts[k].max
            else
              target = @parts[k].reverse.find{ |m| m < value }
            end
            while current.send(PARTS[k][:send]) != target && safety < 100000
              current = current - PARTS[k][:size]
              safety+=1
            end
          end
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

  end

end
