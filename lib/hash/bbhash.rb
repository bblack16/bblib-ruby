require_relative 'hash_path'

class Hash

  # Merges with another hash but also merges all nested hashes and arrays/values.
  # Based on method found @ http://stackoverflow.com/questions/9381553/ruby-merge-nested-hash
  def deep_merge with, merge_arrays: true, overwrite: true
      merger = proc{ |k, v1, v2|
        if v1.is_a?(Hash) && v2.is_a?(Hash)
          v1.merge(v2, &merger)
        else
          if merge_arrays && v1.is_a?(Array) && v2.is_a?(Array)
            v1 + v2
          else
            overwrite || v1 == v2 ? v2 : [v1, v2].flatten
          end
        end
      }
      self.merge(with, &merger)
  end

  def deep_merge! with, merge_arrays: true, overwrite_vals: true
    replace self.deep_merge(with, merge_arrays: merge_arrays, overwrite_vals: overwrite_vals)
  end

  # Converts the keys of the hash as well as any nested hashes to symbols.
  # Based on method found @ http://stackoverflow.com/questions/800122/best-way-to-convert-strings-to-symbols-in-hash
  def keys_to_sym clean: false
    self.inject({}){|memo,(k,v)| memo[clean ? k.to_s.to_clean_sym : k.to_s.to_sym] = (v.is_a?(Hash) || v.is_a?(Array) ? v.keys_to_sym(clean:clean) : v); memo}
  end

  def keys_to_sym! clean: false
    replace(self.keys_to_sym clean:clean)
  end

  # Converts the keys of the hash as well as any nested hashes to strings.
  def keys_to_s
    self.inject({}){|memo,(k,v)| memo[k.to_s] = (v.is_a?(Hash) || v.is_a?(Array) ? v.keys_to_s : v); memo}
  end

  def keys_to_s!
    replace(self.keys_to_s)
  end

  # Reverses the order of keys in the Hash
  def reverse
    self.to_a.reverse.to_h
  end

  def reverse!
    replace self.reverse
  end

  def unshift hash, value = nil
    hash = {hash => value} if !hash.is_a? Hash
    replace hash.merge(self).merge(hash)
  end

  def to_xml level: 0, key:nil
    map do |k,v|
      nested = v.respond_to?(:to_xml)
      array = v.is_a?(Array)
      value = nested ? v.to_xml(level:level + (array ? 0 : 1), key:k) : v
      (array ? '' : ("\t" * level + "<#{k}>\n")) +
      (nested ? '' : "\t" * (level + 1)) +
      "#{value}\n" +
      "\t" * level +
      (array ? '' : "</#{k}>\n")
    end.join.split("\n").reject{ |r| r.strip == '' }.join("\n")
  end

end
