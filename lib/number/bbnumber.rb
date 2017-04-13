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
