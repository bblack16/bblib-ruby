
module BBLib

  # Takes two arrays (can be of different length) and interleaves them like [a[0], b[0], a[1], b[1]...]
  def self.interleave a, b, filler: nil
    if a.size < b.size
      a = a.dup
      while a.size < b.size
        a.push filler
      end
    end
    a.zip(b).flatten(1)
  end

end

class Array
  def msplit *delims, keep_empty: false
    self.map{ |i| i.msplit(delims, keep_empty:keep_empty)}.flatten
  end

  def keys_to_sym clean: false
    self.map{ |v| Hash === v || Array === v ? v.keys_to_sym(clean:clean) : v }
  end

  def keys_to_s clean: false
    self.map{ |v| Hash === v || Array === v ? v.keys_to_s : v }
  end

  def to_xml level: 0, key:nil
    map do |v|
      nested = v.respond_to?(:to_xml)
      value = nested ? v.to_xml(level:level+1, key:key) : v
      "\t"*level + "<#{key}>\n" + (nested ? '' : "\t"*(level+1)) + "#{value}\n" + "\t"*level + "</#{key}>\n"
    end.join
  end

  def interleave b, filler: nil
    BBLib.interleave self, b, filler: filler
  end
end
