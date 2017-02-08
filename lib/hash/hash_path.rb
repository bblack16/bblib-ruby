# frozen_string_literal: true
require_relative 'hash_path_part'
require_relative 'hash_path_proc'

class HashPath < BBLib::LazyClass
  attr_ary_of Part, :parts, default: [], serialize: true

  def append(path)
    insert(path, parts.size)
  end

  def prepend(path)
    insert(path, 0)
  end

  def insert(path, index)
    parse_path(path).each do |part|
      @parts[index] = part
      index += 1
    end
  end

  def find(hash)
    hash = TreeHash.new unless hash.is_a?(TreeHash)
    hash.find(self)
  end

  protected

  def lazy_init(*args)
    args.find_all { |a| a.is_a?(String) }.each do |path|
      append(path)
    end
  end

  # TODO Better recursive detection
  def parse_path(path)
    path.to_s.gsub('..', '.[[:recursive:]]').scan(/(?:[\(|\[|\/].*?[\)|\]|\/]|[^\.])+/).map do |part|
      Part.new(part)
    end
  end
end

module BBLib
  def self.hash_path(hash, *paths, multi_path: false, multi_join: false)
    TreeHash.new(hash).find(paths).map(&:value)
    # if multi_path || multi_join
    #   results = paths.map { |path| BBLib.hash_path(hash, path) }
    #   results = (0..results.max_by(&:size).size - 1).map { |i| results.map { |r| r[i] } } if multi_join
    #   return results
    # end
    # path = split_path(*paths)
    # matches = [hash]
    # recursive = false
    # until path.empty? || matches.empty?
    #   current = path.shift.to_s
    #   current = current[0..-2] + '.' + path.shift.to_s if current.end_with?('\\')
    #   if current.strip == ''
    #     recursive = true
    #     next
    #   end
    #   key, formula = BBLib.analyze_hash_path(current)
    #   matches = matches.flat_map do |match|
    #     if recursive
    #       match.dive(key.to_sym, key)
    #     elsif key == '*'
    #       match.is_a?(Hash) ? match.values : (match.is_a?(Array) ? match : nil)
    #     elsif match.is_a?(Hash)
    #       key.is_a?(Regexp) ? match.map { |k, v| k.to_s =~ key ? v : nil } : [(BBLib.in_opal? ? nil : match[key.to_sym]), match[key]]
    #     elsif match.is_a?(Array) && (key.is_a?(Integer) || key.is_a?(Range))
    #       key.is_a?(Range) ? match[key] : [match[key]]
    #     end
    #   end.compact
    #   matches = BBLib.analyze_hash_path_formula(formula, matches)
    #   recursive = false
    # end
    # matches
  end

  def self.hash_path_keys(hash)
    hash.squish.keys
  end

  def self.hash_path_key_for(hash, value)
    hash.squish.find_all { |_k, v| value.is_a?(Regexp) ? v =~ value : v == value }.to_h.keys
  end

  def self.hash_path_set(hash, *paths, symbols: true, bridge: true)
    paths = paths.find { |a| a.is_a?(Hash) }
    paths.each do |path, value|
      parts = split_path(path)
      matches = BBLib.hash_path(hash, *parts[0..-2])
      matches.each do |match|
        key, _formula = BBLib.analyze_hash_path(parts.last)
        key = match.include?(key.to_sym) || (symbols && !match.include?(key)) ? key.to_sym : key
        if match.is_a?(Hash)
          match[key] = value
        elsif match.is_a?(Array) && key.is_a?(Integer)
          match[key] = value
        end
      end
      hash.bridge(path, value: value, symbols: symbols) if matches.empty? && bridge
    end
    hash
  end

  def self.hash_path_copy(hash, *paths, symbols: true, array: false, overwrite: true, skip_nil: true)
    paths = paths.find { |a| a.is_a?(Hash) }
    paths.each do |from, to|
      value = BBLib.hash_path(hash, from)
      value = value.first unless array
      hash.bridge(to, value: value, symbols: symbols, overwrite: overwrite) unless value.nil? && skip_nil
    end
    hash
  end

  def self.hash_path_copy_to(from, to, *paths, symbols: true, array: false, overwrite: true, skip_nil: true)
    paths = paths.find { |a| a.is_a?(Hash) }
    paths.each do |p_from, p_to|
      value = BBLib.hash_path(from, p_from)
      value = value.first unless array
      to.bridge(p_to, value: value, symbols: symbols, overwrite: overwrite) unless value.nil? && skip_nil
    end
    to
  end

  def self.hash_path_delete(hash, *paths)
    deleted = []
    paths.each do |path|
      parts = split_path(path)
      BBLib.hash_path(hash, *parts[0..-2]).each do |match|
        key, _formula = BBLib.analyze_hash_path(parts.last)
        if match.is_a?(Hash)
          deleted << match.delete(key) << match.delete(key.to_sym)
        elsif match.is_a?(Array) && key.is_a?(Integer)
          deleted << match.delete_at(key)
        end
      end
    end
    deleted.flatten.reject(&:nil?)
  end

  def self.hash_path_move(hash, *paths)
    BBLib.hash_path_copy hash, *paths
    BBLib.hash_path_delete hash, *paths.find { |pt| pt.is_a?(Hash) }.keys
    hash
  end

  def self.hash_path_move_to(from, to, *paths)
    BBLib.hash_path_copy_to from, to, *paths
    BBLib.hash_path_delete from, *paths.find { |pt| pt.is_a?(Hash) }.keys
    to
  end

  def self.split_path(*paths)
    paths.map { |pth| pth.to_s.gsub('..', '. .').scan(/(?:[\(|\[].*?[\)|\]]|[^\.])+/) }.flatten
  end

  def self.analyze_hash_path(path)
    return '', nil if path == '' || path.nil?
    key = path.scan(/^.*^[^\(]*/i).first.to_s
    if key =~ /^\[\d+\]$/
      key = key[1..-2].to_i
    elsif key =~ /\[\-?\d+\.\s?\.{1,2}\-?\d+\]/
      bounds = key.scan(/\-?\d+/).map(&:to_i)
      key = key =~ /\.\s?\.{2}/ ? (bounds.first...bounds.last) : (bounds.first..bounds.last)
    elsif key =~ /\/.*\/i?$/
      key = if key.end_with?('i')
              /#{key[1..-3]}/i
            else
              /#{key[1..-2]}/
            end
    end
    formula = path.scan(/\(.*\)/).first
    [key, formula]
  end

  def self.analyze_hash_path_formula(formula, hashes)
    return hashes unless formula
    hashes.map do |hash|
      begin
        if eval(formula.gsub('$', (hash.is_a?(Hash) ? "(#{hash})" : hash.to_s)))
          hash
        end
      rescue StandardError => e
        e # Do Nothing, the formula failed...
      end
    end.reject(&:nil?)
  end

  def self.hash_path_nav(obj, path = '', delimiter = '.', &block)
    case obj
    when Hash
      obj.each { |k, v| hash_path_nav(v, (path.nil? ? k.to_s.gsub(delimiter, "\\#{delimiter}") : [path, k.to_s.gsub(delimiter, "\\#{delimiter}")].join(delimiter)).to_s, delimiter, &block) }
    when Array
      obj.each_with_index do |o, index|
        hash_path_nav(o, (path.nil? ? "[#{index}]" : [path, "[#{index}]"].join(delimiter)).to_s, delimiter, &block)
      end
    else
      yield path, obj
    end
  end
end

class Hash
  def hash_path(*path)
    BBLib.hash_path self, *path
  end

  def hash_path_set(*paths)
    BBLib.hash_path_set self, *paths
  end

  def hash_path_copy(*paths)
    BBLib.hash_path_copy self, *paths
  end

  def hash_path_copy_to(to, *paths)
    BBLib.hash_path_copy_to self, to, *paths
  end

  def hash_path_delete(*paths)
    BBLib.hash_path_delete self, *paths
  end

  def hash_path_move(*paths)
    BBLib.hash_path_move self, *paths
  end

  def hash_path_move_to(to, *paths)
    BBLib.hash_path_move_to self, to, *paths
  end

  def hash_paths
    BBLib.hash_path_keys self
  end

  def hash_path_for(value)
    BBLib.hash_path_key_for self, value
  end

  alias hpath hash_path
  alias hpath_set hash_path_set
  alias hpath_move hash_path_move
  alias hpath_move_to hash_path_move_to
  alias hpath_delete hash_path_delete
  alias hpath_copy hash_path_copy
  alias hpath_copy_to hash_path_copy_to
  alias hpaths hash_paths
  alias hpath_for hash_path_for

  # Returns all matching values with a specific key (or keys) recursively within a Hash (including nested Arrays)
  def dive(*keys)
    matches = []
    each do |k, v|
      matches << v if keys.any? { |a| (a.is_a?(Regexp) ? a =~ k : a == k) }
      matches += v.dive(*keys) if v.respond_to?(:dive)
    end
    matches
  end

  # Turns nested values' keys into delimiter separated paths
  def squish(delimiter: '.')
    sh = {}
    BBLib.hash_path_nav(dup, nil, delimiter) { |k, v| sh[k] = v }
    sh
  end

  # Expands keys in a hash using a delimiter. Opposite of squish.
  def expand(**args)
    eh = {}
    dup.each do |k, v|
      eh.bridge k, args.merge(value: v)
    end
    eh
  end

  # Add a hash path to a hash
  def bridge(*path, value: nil, delimiter: '.', symbols: true, overwrite: false)
    escaped = "\\#{delimiter}"
    path = path.map { |path| path.gsub(escaped, '[[::SAVE::]]') }
    path = path.msplit(delimiter).flatten
    path = path.map { |path| path.gsub('[[::SAVE::]]', delimiter) }
    hash = self
    part = nil
    bail = false
    until path.empty? || bail
      part = path.shift
      if part =~ /\A\[\d+\]\z/
        part = part[1..-2].to_i
      elsif symbols
        part = part.to_sym
      end
      if (hash.is_a?(Hash) && hash.include?(part) || hash.is_a?(Array) && hash.size > part.to_i) && !overwrite
        bail = true if !hash[part].is_a?(Hash) && !hash[part].is_a?(Array)
        hash = hash[part] unless bail
      else
        hash[part] ||= path.first =~ /\A\[\d+\]\z/ ? [] : {}
        hash = hash[part] unless bail || path.empty?
      end
    end
    hash[part] = value unless bail
    self
  end
end

class Array
  def hash_path(*path)
    BBLib.hash_path self, *path
  end

  def hash_path_set(*paths)
    BBLib.hash_path_set self, *paths
  end

  def hash_path_copy(*paths)
    BBLib.hash_path_copy self, *paths
  end

  def hash_path_copy_to(to, *paths)
    BBLib.hash_path_copy_to self, to, *paths
  end

  def hash_path_delete(*paths)
    BBLib.hash_path_delete self, *paths
  end

  def hash_path_move(*paths)
    BBLib.hash_path_move self, *paths
  end

  def hash_path_move_to(to, *paths)
    BBLib.hash_path_move_to self, to, *paths
  end

  def hash_paths
    BBLib.hash_path_keys self
  end

  def hash_path_for(value)
    BBLib.hash_path_key_for self, value
  end

  alias hpath hash_path
  alias hpath_set hash_path_set
  alias hpath_move hash_path_move
  alias hpath_move_to hash_path_move_to
  alias hpath_delete hash_path_delete
  alias hpath_copy hash_path_copy
  alias hpath_copy_to hash_path_copy_to
  alias hpaths hash_paths
  alias hpath_for hash_path_for

  def dive(*keys)
    matches = []
    each do |i|
      matches+= i.dive(*keys) if i.respond_to?(:dive)
    end
    matches
  end

  # Turns nested values' keys into delimiter separated paths
  def squish(delimiter: '.')
    sh = {}
    BBLib.hash_path_nav(dup, nil, delimiter) { |k, v| sh[k] = v }
    sh
  end

  # Expands keys in a hash using a delimiter. Opposite of squish.
  def expand(**args)
    eh = {}
    dup.each do |k, v|
      eh.bridge k, args.merge(value: v)
    end
    eh
  end
end
