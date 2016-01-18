

class Array
  def msplit delims, keep_empty: false
    self.map{ |i| i.msplit(delims, keep_empty:keep_empty)}.flatten
  end
end
