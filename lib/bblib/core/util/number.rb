module BBLib
  # Used to keep any numeric number between a set of bounds.
  # Passing nil as min or max represents no bounds in that direction.
  # min and max are inclusive to the allowed bounds.
  def self.keep_between(num, min, max)
    num = num.to_f unless num.is_a?(Numeric)
    num = min if min && num < min
    num = max if max && num > max
    num
  end

  # Similar to keep between but when a number exceeds max or is less than min
  # it is looped to the min or max value respectively.
  def self.loop_between(num, min, max)
    num = num.to_f unless num.is_a?(Numeric)
    num = max if min && num < min
    num = min if max && num > max
    num
  end

  NUMBER_WORDS = {
    special: {
      0 => nil,
      1 => 'one',
      2 => 'two',
      3 => 'three',
      4 => 'four',
      5 => 'five',
      6 => 'six',
      7 => 'seven',
      8 => 'eight',
      9 => 'nine',
      10 => 'ten',
      11 => 'eleven',
      12 => 'twleve',
      13 => 'thirteen',
      14 => 'fourteen',
      15 => 'fifteen',
      16 => 'sixteen',
      17 => 'seventeen',
      18 => 'eighteen',
      19 => 'nineteen'
    },
    double_range: {
      2 => 'twenty',
      3 => 'thirty',
      4 => 'forty',
      5 => 'fifty',
      6 => 'sixty',
      7 => 'seventy',
      8 => 'eighty',
      9 => 'ninety'
    },
    ranges: [
      nil, 'thousand', 'million', 'billion', 'trillion', 'quadrillion',
      'quintillion', 'sextillion', 'septillion'
    ]
  }

  # TODO: Support floats eventually?
  def self.number_spelled_out(number, range = 0, include_and: true)
    number = number.to_i
    negative = number.negative?
    number = number * -1 if negative
    return 'zero' if number.zero?
    str = []
    three_digit = number > 999 ? number.to_s[-3..-1].to_i : number
    case three_digit
    when 1..19
      str << NUMBER_WORDS[:special][three_digit]
    when 20..99
      str << NUMBER_WORDS[:double_range][three_digit.to_s[-2].to_i]
      str << NUMBER_WORDS[:special][three_digit.to_s[-1].to_i]
    when 100..999
      str << NUMBER_WORDS[:special][three_digit.to_s[0].to_i]
      str << 'hundred'
      str << 'and' if include_and && !three_digit.to_s.end_with?('00')
      if three_digit.to_s[-2].to_i == 1
        str << NUMBER_WORDS[:special][three_digit.to_s[-2..-1].to_i]
      else
        str << NUMBER_WORDS[:double_range][three_digit.to_s[-2].to_i]
        str << NUMBER_WORDS[:special][three_digit.to_s[-1].to_i]
      end
    end
    str << NUMBER_WORDS[:ranges][range] unless str.compact.empty?
    (negative ? 'negative ' : '') +
    ((number.to_s.size > 3 ? "#{number_spelled_out(number.to_s[0..-4].to_i, range + 1)} " : '') +
    str.compact.join(' ')).gsub(/\s+/, ' ')
  end
end
