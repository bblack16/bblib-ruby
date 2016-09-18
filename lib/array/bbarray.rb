
module BBLib

  # Takes two arrays (can be of different length) and interleaves them like [a[0], b[0], a[1], b[1]...]
  def self.interleave a, b
    ary = Array.new
    [a.size, b.size].max.times do |i|
      ary.push(a[i]) if i < a.size
      ary.push(b[i]) if i < b.size
    end
    ary
  end

end

class Array

  def msplit *delims, keep_empty: false
    self.map{ |i| i.msplit(delims, keep_empty:keep_empty)}.flatten
  end
  alias_method :multi_split, :msplit

  def keys_to_sym clean: false
    self.map{ |v| v.is_a?(Hash) || v.is_a?(Array) ? v.keys_to_sym(clean:clean) : v }
  end

  def keys_to_s clean: false
    self.map{ |v| v.is_a?(Hash) || v.is_a?(Array) ? v.keys_to_s : v }
  end

  def to_xml level: 0, key:nil
    map do |v|
      nested = v.respond_to?(:to_xml)
      value = nested ? v.to_xml(level:level + 1, key:key) : v
      "\t" * level + "<#{key}>\n" +
      (nested ? '' : "\t"*(level+1)) +
      "#{value}\n" +
      "\t"*level + "</#{key}>\n"
    end.join
  end

  def interleave b
    BBLib.interleave self, b
  end

  def diff b
    (self-b) + (b-self)
  end
  
end
