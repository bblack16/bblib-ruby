

module BBLib

  def self.parse_duration str, to = :sec
    secs = 0.0
    TIME_EXPS.each do |k, v|
      v[:exp].each do |e|
        numbers = str.scan(/^.\d+(?=#{e} )/i) + str.scan(/^.\d+(?=#{e}\z)/i) + str.scan(/\d+.\d+(?=#{e} )/i) + str.scan(/\d+.\d+(?=#{e}\z)/i)
        # puts numbers
        numbers.each do |n|
          secs+= n.to_i * v[:mult]
        end
      end
    end
    return secs / TIME_EXPS[to][:mult].to_f
  end

  private

    TIME_EXPS = {
      mili: { mult: 0.001, exp: ['ms', 'mil', 'mili', 'milisecond', 'milsec', 'msec', 'msecond']},
      sec: { mult: 1, exp: ['s', 'sec', 'second']},
      min: { mult: 60, exp: ['m', 'mn', 'min', 'minute']},
      hour: { mult: 3600, exp: ['h', 'hr', 'hour']},
      day: { mult: 86400, exp: ['d', 'day']},
      week: { mult: 604800, exp: ['w', 'wk', 'week']},
      month: { mult: 2592000, exp: ['mo', 'mon', 'month', 'mnth', 'mth']},
      year: { mult: 31536000, exp: ['y', 'yr', 'year']}
    }

end

class String
  def parse_duration to = :sec
    BBLib.parse_duration self, to
  end
end
