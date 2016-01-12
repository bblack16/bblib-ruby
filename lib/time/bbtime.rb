

module BBLib

  # Parses known time based patterns out of a string to construct a numeric duration.
  def self.parse_duration str, output: :sec
    secs = 0.0
    TIME_EXPS.each do |k, v|
      v[:exp].each do |e|
        numbers = str.downcase.scan(/(?=\w|\D|\A)\d?\.?\d+[[:space:]]*#{e}(?=\W|\d|\z)/i)
        numbers.each do |n|
          secs+= n.to_i * v[:mult]
        end
      end
    end
    secs / (TIME_EXPS[output][:mult].to_f rescue 1)
  end

  # Turns a numeric input into a time string.
  def self.to_duration num, input: :sec, stop: :milli, style: :medium
    return nil unless Numeric === num || num > 0
    if ![:full, :medium, :short].include?(style) then style = :medium end
    expression = []
    n, done = num * TIME_EXPS[input.to_sym][:mult], false
    TIME_EXPS.reverse.each do |k, v|
      next unless !done
      div = n / v[:mult]
      if div > 1
        expression << "#{div.floor}#{v[:styles][style]}#{div.floor > 1 && style != :short ? "s" : nil}"
        n-= div.floor * v[:mult]
      end
      if k == stop then done = true end
    end
    expression.join ' '
  end

  TIME_EXPS = {
    milli: {
      mult: 0.001,
      styles: {full: ' millisecond', medium: ' milli', short: 'ms'},
      exp: ['ms', 'mil', 'mils', 'milli', 'millis', 'millisecond', 'milliseconds', 'milsec', 'milsecs', 'msec', 'msecs', 'msecond', 'mseconds']},
    sec: {
      mult: 1,
      styles: {full: ' second', medium: ' sec', short: 's'},
      exp: ['s', 'sec', 'secs', 'second', 'seconds']},
    min: {
      mult: 60,
      styles: {full: ' minute', medium: ' min', short: 'm'},
      exp: ['m', 'mn', 'mns', 'min', 'mins', 'minute', 'minutes']},
    hour: {
      mult: 3600,
      styles: {full: ' hour', medium: ' hr', short: 'h'},
      exp: ['h', 'hr', 'hrs', 'hour', 'hours']},
    day: {
      mult: 86400,
      styles: {full: ' day', medium: ' day', short: 'd'},
      exp: ['d', 'day' 'days']},
    week: {
      mult: 604800,
      styles: {full: ' week', medium: ' wk', short: 'w'},
      exp: ['w', 'wk', 'wks', 'week', 'weeks']},
    month: {
      mult: 2592000,
      styles: {full: ' month', medium: ' mo', short: 'mo'},
      exp: ['mo', 'mon', 'mons', 'month', 'months', 'mnth', 'mnths', 'mth', 'mths']},
    year: {
      mult: 31536000,
      styles: {full: ' year', medium: ' yr', short: 'y'},
      exp: ['y', 'yr', 'yrs', 'year', 'years']}
  }

end

class String
  def parse_duration output: :sec
    BBLib.parse_duration self, output:output
  end
end

class Numeric
  def to_duration input: :sec, stop: :milli, style: :medium
    BBLib.to_duration self, input: input, stop: stop, style: style
  end
end
