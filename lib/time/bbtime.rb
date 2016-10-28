require_relative 'task_timer'
require_relative 'cron'

module BBLib

  # Parses known time based patterns out of a string to construct a numeric duration.
  def self.parse_duration str, output: :sec, min_interval: :sec
    msecs = 0.0

    # Parse time expressions such as 04:05.
    # The argument min_interval controls what time interval the final number represents
    str.scan(/\d+\:[\d+\:]+\d+/).each do |e|
      keys = TIME_EXPS.keys
      position = keys.index(min_interval)
      e.split(':').reverse.each do |sec|
        key = keys[position]
        msecs+= sec.to_f * TIME_EXPS[key][:mult]
        position+=1
      end
    end

    # Parse expressions such as '1m' or '1 min'
    TIME_EXPS.each do |k, v|
      v[:exp].each do |e|
        numbers = str.downcase.scan(/(?=\w|\D|\A)\d*\.?\d+[[:space:]]*#{e}(?=\W|\d|\z)/i)
        numbers.each do |n|
          msecs+= n.to_f * v[:mult]
        end
      end
    end

    msecs / (TIME_EXPS[output][:mult] rescue 1)
  end

  # Turns a numeric input into a time string.
  def self.to_duration num, input: :sec, stop: :milli, style: :medium
    return nil unless Numeric === num
    return '0' if num == 0
    if ![:full, :medium, :short].include?(style) then style = :medium end
    expression = []
    n, done = num * TIME_EXPS[input.to_sym][:mult], false
    TIME_EXPS.reverse.each do |k, v|
      next if done
      done = true if k == stop
      div = n / v[:mult]
      if div >= 1
        val = (done ? div.round : div.floor)
        expression << "#{val}#{v[:styles][style]}#{val > 1 && style != :short ? "s" : nil}"
        n-= val.to_f * v[:mult]
      end
    end
    expression.join ' '
  end

  TIME_EXPS = {
    yocto: {
      mult: 0.000000000000000000001,
      styles: {full: ' yoctosecond', medium: ' yocto', short: 'ys'},
      exp: ['yoctosecond', 'yocto', 'yoctoseconds', 'yoctos', 'ys']
    },
    zepto: {
      mult: 0.000000000000000001,
      styles: {full: ' zeptosecond', medium: ' zepto', short: 'zs'},
      exp: ['zeptosecond', 'zepto', 'zeptoseconds', 'zeptos', 'zs']
    },
    atto: {
      mult: 0.000000000000001,
      styles: {full: ' attosecond', medium: ' atto', short: 'as'},
      exp: ['attoseconds', 'atto', 'attoseconds', 'attos', 'as']
    },
    femto: {
      mult: 0.000000000001,
      styles: {full: ' femtosecond', medium: ' fempto', short: 'fs'},
      exp: ['femtosecond', 'fempto', 'femtoseconds', 'femptos', 'fs']
    },
    pico: {
      mult: 0.000000001,
      styles: {full: ' picosecond', medium: ' pico', short: 'ps'},
      exp: ['picosecond', 'pico', 'picoseconds', 'picos', 'ps']
    },
    nano: {
      mult: 0.000001,
      styles: {full: ' nanosecond', medium: ' nano', short: 'ns'},
      exp: ['nanosecond', 'nano', 'nanoseconds', 'nanos', 'ns']
    },
    micro: {
      mult: 0.001,
      styles: {full: ' microsecond', medium: ' micro', short: 'μs'},
      exp: ['microsecond', 'micro', 'microseconds', 'micros', 'μs']
    },
    milli: {
      mult: 1,
      styles: {full: ' millisecond', medium: ' mil', short: 'ms'},
      exp: ['ms', 'mil', 'mils', 'milli', 'millis', 'millisecond', 'milliseconds', 'milsec', 'milsecs', 'msec', 'msecs', 'msecond', 'mseconds']},
    sec: {
      mult: 1000,
      styles: {full: ' second', medium: ' sec', short: 's'},
      exp: ['s', 'sec', 'secs', 'second', 'seconds']},
    min: {
      mult: 60000,
      styles: {full: ' minute', medium: ' min', short: 'm'},
      exp: ['m', 'mn', 'mns', 'min', 'mins', 'minute', 'minutes']},
    hour: {
      mult: 3600000,
      styles: {full: ' hour', medium: ' hr', short: 'h'},
      exp: ['h', 'hr', 'hrs', 'hour', 'hours']},
    day: {
      mult: 86400000,
      styles: {full: ' day', medium: ' day', short: 'd'},
      exp: ['d', 'day', 'days']},
    week: {
      mult: 604800000,
      styles: {full: ' week', medium: ' wk', short: 'w'},
      exp: ['w', 'wk', 'wks', 'week', 'weeks']},
    month: {
      mult: 2592000000,
      styles: {full: ' month', medium: ' mo', short: 'mo'},
      exp: ['mo', 'mon', 'mons', 'month', 'months', 'mnth', 'mnths', 'mth', 'mths']},
    year: {
      mult: 31536000000,
      styles: {full: ' year', medium: ' yr', short: 'y'},
      exp: ['y', 'yr', 'yrs', 'year', 'years']}
  }

end

class String
  def parse_duration output: :sec, min_interval: :sec
    BBLib.parse_duration self, output:output, min_interval:min_interval
  end
end

class Numeric
  def to_duration input: :sec, stop: :milli, style: :medium
    BBLib.to_duration self, input: input, stop: stop, style: style
  end
end
