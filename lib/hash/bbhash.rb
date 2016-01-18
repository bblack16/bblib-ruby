require_relative 'hash_path'

class Hash

  # Returns all matching values with a specific key (or Array of keys) recursively within a Hash (included nested Arrays)
  def dig keys, search_arrays: true
    keys = [keys].flatten
    matches = []
    self.each do |k, v|
      if keys.any?{ |a| (a.is_a?(Regexp) ? a =~ k : a == k ) } then matches << v end
      if v.is_a? Hash
        matches+= v.dig(keys)
      elsif v.is_a?(Array) && search_arrays
        v.flatten.each{ |i| if i.is_a?(Hash) then matches+= i.dig(keys) end }
      end
    end
    matches
  end

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
  def keys_to_sym clean: false
    self.inject({}){|memo,(k,v)| memo[clean ? k.to_s.to_clean_sym : k.to_s.to_sym] = (Hash === v ? v.keys_to_sym : v); memo}
  end

  def keys_to_sym! clean: false
    replace(self.keys_to_sym clean:clean)
  end

  # Converts the keys of the hash as well as any nested hashes to strings.
  def keys_to_string
    self.inject({}){|memo,(k,v)| memo[k.to_s] = (Hash === v ? v.keys_to_string : v); memo}
  end

  def keys_to_string!
    replace(self.keys_to_string)
  end

  # Reverses the order of keys in the Hash
  def reverse
    self.to_a.reverse.to_h
  end

  def reverse!
    replace self.reverse
  end

  def unshift hash, value = nil
    if !hash.is_a? Hash then hash = {hash => value} end
    replace hash.merge(self).merge(hash)
  end

end
