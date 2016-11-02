module BBLib
  # Used to keep any numeric number between a set of bounds.
  # Passing nil as min or max represents no bounds in that direction.
  # min and max are inclusive to the allowed bounds.
  def self.keep_between(num, min, max)
    raise "Argument must be numeric: #{num} (#{num.class})" unless num.is_a?(Numeric)
    num = min if min && num < min
    num = max if max && num > max
    num
  end
end
