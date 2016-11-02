require_relative 'hash_path'
require_relative 'path_hash'

class Hash
  # Merges with another hash but also merges all nested hashes and arrays/values.
  def deep_merge(with, merge_arrays: true, overwrite: true)
    merger = proc do |_k, v1, v2|
      if BBLib.are_all?(Hash, v1, v2)
        v1.merge(v2, &merger)
      elsif merge_arrays && BBLib.are_all?(Array, v1, v2)
        v1 + v2
      else
        overwrite || v1 == v2 ? v2 : [v1, v2].flatten
      end
    end
    merge(with, &merger)
  end

  def deep_merge!(*args)
    replace deep_merge(*args)
  end

  # Converts the keys of the hash as well as any nested hashes to symbols.
  def keys_to_sym(clean: false)
    each_with_object({}) do |(k, v), memo|
      key = clean ? k.to_s.to_clean_sym : k.to_s.to_sym
      memo[key] = v.respond_to?(:keys_to_sym) ? v.keys_to_sym(clean: clean) : v
    end
  end

  def keys_to_sym!(clean: false)
    replace(keys_to_sym(clean: clean))
  end

  # Converts the keys of the hash as well as any nested hashes to strings.
  def keys_to_s
    each_with_object({}) do |(k, v), memo|
      memo[k.to_s] = v.respond_to?(:keys_to_sym) ? v.keys_to_s : v
    end
  end

  def keys_to_s!
    replace(keys_to_s)
  end

  # Reverses the order of keys in the Hash
  def reverse
    to_a.reverse.to_h
  end

  def reverse!
    replace(reverse)
  end

  def unshift(hash, value = nil)
    hash = { hash => value } unless hash.is_a?(Hash)
    replace hash.merge(self).merge(hash)
  end
end
