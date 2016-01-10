class Hash

  # Merges with another hash but also merges all nested hashes and arrays/values.
  # Based on method found @ http://stackoverflow.com/questions/9381553/ruby-merge-nested-hash
  def deep_merge with, merge_arrays: true, overwrite_vals: true
      merger = proc{ |k, v1, v2| v1.is_a?(Hash) && v2.is_a?(Hash) ? v1.merge(v2, &merger) : (merge_arrays && v1.is_a?(Array) && v2.is_a?(Array) ? (v1 + v2) : (overwrite_vals ? v2 : [v1, v2].flatten)) }
      self.merge(with, &merger)
  end

  def deep_merge! with, merge_arrays: true, overwrite_vals: true
    replace self.deep_merge(with, merge_arrays: merge_arrays, overwrite_vals: overwrite_vals)
  end

  # Converts the keys of the hash as well as any nested hashes to symbols.
  # Based on method found @ http://stackoverflow.com/questions/800122/best-way-to-convert-strings-to-symbols-in-hash
  def keys_to_sym
    self.inject({}){|memo,(k,v)| memo[k.to_sym] = (Hash === v ? v.keys_to_sym : v); memo}
  end

  def keys_to_sym!
    replace self.keys_to_sym
  end

  # Reverses the order of keys in the Hash
  def reverse
    self.to_a.reverse.to_h
  end

  def reverse!
    replace self.reverse
  end

end
