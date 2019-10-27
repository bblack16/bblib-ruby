
class Hash
  # Merges with another hash but also merges all nested hashes and arrays/values.
  def deep_merge(with, merge_arrays: true, overwrite: true, uniq: false)
    merger = proc do |_k, v1, v2|
      if BBLib.are_all?(Hash, v1, v2)
        v1.merge(v2, &merger)
      elsif merge_arrays && BBLib.are_all?(Array, v1, v2)
        uniq ? (v1 + v2).uniq : v1 + v2
      else
        overwrite || v1 == v2 ? v2 : (uniq ? [v1, v2].flatten.uniq : [v1, v2].flatten)
      end
    end
    merge(with, &merger)
  end

  # In place version of deep_merge
  def deep_merge!(*args)
    replace deep_merge(*args)
  end

  # Converts the keys of the hash as well as any nested hashes to symbols.
  def keys_to_sym(clean: false, recursive: true)
    each_with_object({}) do |(k, v), memo|
      key = clean ? k.to_s.to_clean_sym : k.to_s.to_sym
      memo[key] = recursive && v.respond_to?(:keys_to_sym) ? v.keys_to_sym(clean: clean) : v
    end
  end

  # In place version of keys_to_sym
  def keys_to_sym!(clean: false, recursive: true)
    replace(keys_to_sym(clean: clean, recursive: recursive))
  end

  # Converts the keys of the hash as well as any nested hashes to strings.
  def keys_to_s(recursive: true)
    each_with_object({}) do |(k, v), memo|
      memo[k.to_s] = recursive && v.respond_to?(:keys_to_sym) ? v.keys_to_s : v
    end
  end

  # In place version of keys_to_s
  def keys_to_s!(recursive: true)
    replace(keys_to_s(recursive: recursive))
  end

  # Reverses the order of keys in the Hash
  def reverse
    to_a.reverse.to_h
  end

  # In place version of reverse
  def reverse!
    replace(reverse)
  end

  # Like unshift for Arrays. Adds a key to the beginning of a Hash rather than the end.
  def unshift(hash, value = nil)
    hash = { hash => value } unless hash.is_a?(Hash)
    replace(hash.merge(self).merge(hash))
  end

  # Displays all of the differences between this hash and another.
  # Checks both key and value pairs.
  def diff(hash)
    to_a.diff(hash.to_a).to_h
  end

  # Returns all matching values with a specific key (or keys) recursively within a Hash (including nested Arrays)
  def dive(*keys)
    matches = []
    each do |k, v|
      matches << v if keys.any? { |key| (key.is_a?(Regexp) ? key =~ k : key == k) }
      matches += v.dive(*keys) if v.respond_to?(:dive)
    end
    matches
  end

  # Navigate a hash using a dot delimited path.
  def path_nav(obj, path = '', delimiter = '.', &block)
    case obj
    when Hash
      if obj.empty?
        yield path, obj
      else
        obj.each do |k, v|
          path_nav(
            v,
            (path ? [path, k.to_s.gsub(delimiter, "\\#{delimiter}")].join(delimiter) : k.to_s.gsub(delimiter, "\\#{delimiter}")).to_s,
            delimiter,
            &block
          )
        end
      end
    when Array
      if obj.empty?
        yield path, obj
      else
        obj.each_with_index do |ob, index|
          path_nav(
            ob,
            (path ? [path, "[#{index}]"].join(delimiter) : "[#{index}]").to_s,
            delimiter,
            &block
          )
        end
      end
    else
      yield path, obj
    end
  end

  # Turns nested values' keys into delimiter separated paths
  def squish(delimiter: '.')
    sh = {}
    path_nav(dup, nil, delimiter) { |k, v| sh[k] = v }
    sh
  end

  # Expands keys in a hash using a delimiter. Opposite of squish.
  def expand
    {}.to_tree_hash.tap do |hash|
      each do |k, v|
        hash.bridge(k => v)
      end
    end.value
  end

  # Returns a version of the hash not including the specified keys
  def only(*args)
    select { |k, _v| args.include?(k) }
  end

  # Returns a version of the hash with the specified keys removed.
  def except(*args)
    reject { |k, _v| args.include?(k) }
  end

  # Convert this hash into a TreeHash object.
  def to_tree_hash
    TreeHash.new(self)
  end

  # Run a map iterator over the values in the hash without changing the keys.
  def vmap
    return map unless block_given?
    map { |k, v| [k, yield(v)] }.to_h
  end

  # Run a map iterator over the keys in the hash without changing the values.
  def kmap
    return map unless block_given?
    map { |k, v| [yield(k), v] }.to_h
  end

  # Map for hash that automatically converts the yield block to a hash.
  # Each yield must produce an array with exactly two elements.
  def hmap
    return map unless block_given?
    map { |k, v| yield(k, v) }.compact.to_h
  end

  # Sort a map by its keys or by using a block, which could then sort by value
  # or some other combination.
  def hsort
    return sort_by { |k, v| k }.to_h unless block_given?
    sort_by { |k, v| yield(k, v) }.to_h
  end
end
