

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
end
