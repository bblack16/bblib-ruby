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
end

class Integer
  # Convert this integer into a string with every three digits separated by a delimiter
  def to_delimited_s(delim = ',')
    self.to_s.reverse.gsub(/(\d{3})/, "\\1#{delim}").reverse.uncapsulate(',')
  end
end

class Float
  # Convert this integer into a string with every three digits separated by a delimiter
  # on the left side of the decimal
  def to_delimited_s(delim = ',')
    split = self.to_s.split('.')
    split[0] = split.first.reverse.gsub(/(\d{3})/, "\\1#{delim}").reverse
    split.join('.').uncapsulate(',')
  end
end
