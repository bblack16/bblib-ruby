require_relative 'hash_path'
require_relative 'path_hash'
require_relative 'tree_hash'

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

  def keys_to_sym!(clean: false, recursive: true)
    replace(keys_to_sym(clean: clean, recursive: recursive))
  end

  # Converts the keys of the hash as well as any nested hashes to strings.
  def keys_to_s(recursive: true)
    each_with_object({}) do |(k, v), memo|
      memo[k.to_s] = recursive && v.respond_to?(:keys_to_sym) ? v.keys_to_s : v
    end
  end

  def keys_to_s!(recursive: true)
    replace(keys_to_s(recursive: recursive))
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

  def diff(hash)
    to_a.diff(hash.to_a).to_h
  end

  # Returns all matching values with a specific key (or keys) recursively within a Hash (including nested Arrays)
  def dive(*keys)
    matches = []
    each do |k, v|
      matches << v if keys.any? { |a| (a.is_a?(Regexp) ? a =~ k : a == k) }
      matches += v.dive(*keys) if v.respond_to?(:dive)
    end
    matches
  end

  def path_nav(obj, path = '', delimiter = '.', &block)
    case obj
    when Hash
      obj.each { |k, v| path_nav(v, (path.nil? ? k.to_s.gsub(delimiter, "\\#{delimiter}") : [path, k.to_s.gsub(delimiter, "\\#{delimiter}")].join(delimiter)).to_s, delimiter, &block) }
    when Array
      obj.each_with_index do |o, index|
        path_nav(o, (path.nil? ? "[#{index}]" : [path, "[#{index}]"].join(delimiter)).to_s, delimiter, &block)
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
  def expand(**args)
    {}.to_tree_hash.tap do |hash|
      each do |k, v|
        hash.bridge(k => v)
      end
    end.value
  end

  def only(*args)
    select { |k, _v| args.include?(k) }
  end

  def except(*args)
    reject { |k, _v| args.include?(k) }
  end

  def to_tree_hash
    TreeHash.new(self)
  end

  def vmap
    return map unless block_given?
    map { |k, v| [k, yield(v)] }.to_h
  end

  def kmap
    return map unless block_given?
    map { |k, v| [yield(k), v] }.to_h
  end

  def hmap
    return map unless block_given?
    map { |k, v| yield(k, v) }.to_h
  end
end
