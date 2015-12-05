

module BBLib

  def self.parse_duration str, to = :sec
    secs = 0.0
    TIME_EXPS.each do |k, v|
      v[:exp].each do |e|
        numbers = BBLib.parse_duration_expression str.downcase, e
        numbers.each do |n|
          secs+= n.to_i * v[:mult]
        end
      end
    end
    return secs / TIME_EXPS[to][:mult].to_f
  end

  private

    TIME_EXPS = {
      mili: { mult: 0.001, exp: ['ms', 'mil', 'mils', 'mili', 'milis', 'milisecond', 'miliseconds', 'milsec', 'milsecs', 'msec', 'msecs', 'msecond', 'mseconds']},
      sec: { mult: 1, exp: ['s', 'sec', 'secs', 'second', 'seconds']},
      min: { mult: 60, exp: ['m', 'mn', 'mns', 'min', 'mins', 'minute', 'minutes']},
      hour: { mult: 3600, exp: ['h', 'hr', 'hrs', 'hour', 'hours']},
      day: { mult: 86400, exp: ['d', 'day' 'days']},
      week: { mult: 604800, exp: ['w', 'wk', 'wks', 'week', 'weeks']},
      month: { mult: 2592000, exp: ['mo', 'mon', 'mons', 'month', 'months', 'mnth', 'mnths', 'mth', 'mths']},
      year: { mult: 31536000, exp: ['y', 'yr', 'yrs', 'year', 'years']}
    }

    def self.parse_duration_expression str, exp
      numbers = []
      numbers+= str.scan(/\A\d+(?=\s?#{exp}[\s,\d])/i)
      numbers+= str.scan(/\s\d+(?=\s?#{exp}[\s,\d])/i)
      numbers+= str.scan(/[[:alpha]]\d+(?=\s?#{exp}[\s,\d])/i)
      numbers+= str.scan(/\A\d+\.\d+(?=\s?#{exp}[\s,\d])/i)
      numbers+= str.scan(/[[:alpha]]\d+\.\d+(?=\s?#{exp}[\s,\d])/i)
      numbers+= str.scan(/\s\d+\.\d+(?=\s?#{exp}[\s,\d])/i)

      numbers+= str.scan(/\A\d+(?=\s?#{exp}\z)/i)
      numbers+= str.scan(/\s\d+(?=\s?#{exp}\z)/i)
      numbers+= str.scan(/[[:alpha]]\d+(?=\s?#{exp}\z)/i)
      numbers+= str.scan(/\A\d+\.\d+(?=\s?#{exp}\z)/i)
      numbers+= str.scan(/[[:alpha]]\d+\.\d+(?=\s?#{exp}\z)/i)
      numbers+= str.scan(/\s\d+\.\d+(?=\s?#{exp}\z)/i)
      return numbers
    end

end

class String
  def parse_duration to = :sec
    BBLib.parse_duration self, to
  end
end
