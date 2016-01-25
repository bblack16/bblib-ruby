module BBLib

  # Used to keep any numeric number between a set of bounds. Passing nil as min or max represents no bounds in that direction.
  # min and max are inclusive to the allowed bounds.
  def self.keep_between num, min, max
    raise "Argument must be numeric: #{num} (#{num.class})" unless Numeric === num
    if !min.nil? && num < min then num = min end
    if !max.nil? && num > max then num = max end
    return num
  end

end
