
module BBLib
  # Takes two arrays (can be of different length) and interleaves
  # them like [a[0], b[0], a[1], b[1]...]
  def self.interleave(a, b)
    ary = []
    [a.size, b.size].max.times do |i|
      ary.push(a[i]) if i < a.size
      ary.push(b[i]) if i < b.size
    end
    ary
  end
end

class Array
  def msplit(*delims, keep_empty: false)
    map { |i| i.msplit(delims, keep_empty: keep_empty) }.flatten
  end
  alias multi_split msplit

  def keys_to_sym(clean: false)
    map { |v| v.is_a?(Hash) || v.is_a?(Array) ? v.keys_to_sym(clean: clean) : v }
  end

  def keys_to_s
    map { |v| v.is_a?(Hash) || v.is_a?(Array) ? v.keys_to_s : v }
  end

  def interleave(b)
    BBLib.interleave self, b
  end

  def diff(b)
    (self-b) + (b-self)
  end
end
