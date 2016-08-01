require_relative 'hash_path_proc'

module BBLib

  def self.hash_path hash, *paths, multi_path: false, multi_join: false
    if multi_path || multi_join
      results = paths.map{ |path| BBLib.hash_path(hash, path)}
      results = (0..results.max_by{ |m| m.size }.size - 1).map{ |i| results.map{ |r| r[i] } } if multi_join
      return results
    end
    path = split_path(*paths)
    matches, recursive = [hash], false
    until path.empty? || matches.empty?
      current = path.shift.to_s
      current = current[0..-2] + '.' + path.shift.to_s if current.end_with?("\\")
      if current.strip == ''
        recursive = true
        next
      end
      key, formula = BBLib.analyze_hash_path(current)
      matches = matches.map do |match|
        if recursive
          match.dive(key.to_sym, key)
        elsif key == '*'
          match.is_a?(Hash) ? match.values : (match.is_a?(Array) ? match : nil)
        elsif match.is_a?(Hash)
          key.is_a?(Regexp) ? match.map{ |k,v| k.to_s =~ key ? v : nil } : [(BBLib::in_opal? ? nil : match[key.to_sym]), match[key]]
        elsif match.is_a?(Array) && (key.is_a?(Fixnum) || key.is_a?(Range))
          key.is_a?(Range) ? match[key] : [match[key]]
        else
          nil
        end
      end.flatten(1).reject{ |m| m.nil? }
      matches = BBLib.analyze_hash_path_formula(formula, matches)
      recursive = false
    end
    matches
  end

  def self.hash_path_keys hash
    hash.squish.keys
  end

  def self.hash_path_key_for hash, value
    hash.squish.find_all{ |k,v| value.is_a?(Regexp) ? v =~ value : v == value }.to_h.keys
  end

  def self.hash_path_set hash, *paths, symbols: true, bridge: true
    paths = paths.find{ |a| a.is_a?(Hash) }
    paths.each do |path, value|
      parts = split_path(path)
      matches = BBLib.hash_path(hash, *parts[0..-2])
      matches.each do |match|
        key, formula = BBLib.analyze_hash_path(parts.last)
        key = match.include?(key.to_sym) || (symbols && !match.include?(key) ) ? key.to_sym : key
        if match.is_a?(Hash)
          match[key] = value
        elsif match.is_a?(Array) && key.is_a?(Fixnum)
          match[key] = value
        end
      end
      hash.bridge(path, value:value, symbols:symbols) if matches.empty? && bridge
    end
    hash
  end

  def self.hash_path_copy hash, *paths, symbols: true, array: false, overwrite: true, skip_nil: true
    paths = paths.find{ |a| a.is_a?(Hash) }
    paths.each do |from, to|
      value = BBLib.hash_path(hash, from)
      value = value.first unless array
      hash.bridge(to, value: value, symbols:symbols, overwrite: overwrite) unless value.nil? && skip_nil
    end
    hash
  end

  def self.hash_path_copy_to from, to, *paths, symbols: true, array: false, overwrite: true, skip_nil: true
    paths = paths.find{ |a| a.is_a?(Hash) }
    paths.each do |p_from, p_to|
      value = BBLib.hash_path(from, p_from)
      value = value.first unless array
      to.bridge(p_to, value:value, symbols:symbols, overwrite: overwrite) unless value.nil? && skip_nil
    end
    to
  end

  def self.hash_path_delete hash, *paths
    deleted = Array.new
    paths.each do |path|
      parts = split_path(path)
      BBLib.hash_path(hash, *parts[0..-2]).each do |match|
        key, formula = BBLib.analyze_hash_path(parts.last)
        if match.is_a?(Hash)
          deleted << match.delete(key) << match.delete(key.to_sym)
        elsif match.is_a?(Array) && key.is_a?(Fixnum)
          deleted << match.delete_at(key)
        end
      end
    end
    deleted.flatten.reject{ |v| v.nil? }
  end

  def self.hash_path_move hash, *paths
    BBLib.hash_path_copy hash, *paths
    BBLib.hash_path_delete hash, *paths.find{|pt| pt.is_a?(Hash) }.keys
    hash
  end

  def self.hash_path_move_to from, to, *paths
    BBLib.hash_path_copy_to from, to, *paths
    BBLib.hash_path_delete from, *paths.find{|pt| pt.is_a?(Hash) }.keys
    to
  end

  protected

    def self.split_path *paths
      paths.map{|pth| pth.to_s.gsub('..', '. .').scan(/(?:[\(|\[].*?[\)|\]]|[^\.])+/)}.flatten
    end

    def self.analyze_hash_path path
      return '', nil if path == '' || path.nil?
      key = path.scan(/^.*^[^\(]*/i).first.to_s
      if key =~ /^\[\d+\]$/
        key = key[1..-2].to_i
      elsif key =~ /\[\-?\d+\.\s?\.{1,2}\-?\d+\]/
        bounds = key.scan(/\-?\d+/).map{|x| x.to_i}
        key = key =~ /\.\s?\.{2}/ ? (bounds.first...bounds.last) : (bounds.first..bounds.last)
      elsif key =~ /\/.*[\/|\/i]$/
        if key.end_with?('i')
          key = /#{key[1..-3]}/i
        else
          key = /#{key[1..-2]}/
        end
      end
      formula = path.scan(/\(.*\)/).first
      return key, formula
    end

    def self.analyze_hash_path_formula formula, hashes
      return hashes unless formula
      hashes.map do |p|
        begin
          if eval(p.is_a?(Hash) ? formula.gsub('$', "(#{p})") : formula.gsub('$', p.to_s))
            p
          else
            nil
          end
        rescue StandardError, Exception => e
          # Do nothing, the formula failed and we reject the value as a false
        end
      end.reject{ |x| x.nil? }
    end

    def self.hash_path_nav obj, path = '', delimiter = '.', &block
      case [obj.class]
      when [Hash]
        obj.each{ |k,v| hash_path_nav(v, "#{path.nil? ? k.to_s : [path, k].join(delimiter)}", delimiter, &block) }
      when [Array]
        index = 0
        obj.each{ |o| hash_path_nav(o, "#{path.nil? ? "[#{index}]" : [path, "[#{index}]" ].join(delimiter)}", delimiter, &block) ; index+=1 }
      else
        yield path, obj
      end
    end

end



class Hash

  def hash_path *path
    BBLib.hash_path self, *path
  end

  def hash_path_set *paths
    BBLib.hash_path_set self, *paths
  end

  def hash_path_copy *paths
    BBLib.hash_path_copy self, *paths
  end

  def hash_path_copy_to to, *paths
    BBLib.hash_path_copy_to self, to, *paths
  end

  def hash_path_delete *paths
    BBLib.hash_path_delete self, *paths
  end

  def hash_path_move *paths
    BBLib.hash_path_move self, *paths
  end

  def hash_path_move_to to, *paths
    BBLib.hash_path_move_to self, to, *paths
  end

  def hash_paths
    BBLib.hash_path_keys self
  end

  def hash_path_for value
    BBLib.hash_path_key_for self, value
  end

  alias_method :hpath, :hash_path
  alias_method :hpath_set, :hash_path_set
  alias_method :hpath_move, :hash_path_move
  alias_method :hpath_move_to, :hash_path_move_to
  alias_method :hpath_delete, :hash_path_delete
  alias_method :hpath_copy, :hash_path_copy
  alias_method :hpath_copy_to, :hash_path_copy_to
  alias_method :hpaths, :hash_paths
  alias_method :hpath_for, :hash_path_for

  # Returns all matching values with a specific key (or Array of keys) recursively within a Hash (including nested Arrays)
  def dive *keys
    matches = Array.new
    self.each do |k, v|
      if keys.any?{ |a| (a.is_a?(Regexp) ? a =~ k : a == k ) } then matches << v end
      if v.respond_to? :dive
        matches+= v.dive(*keys)
      end
    end
    matches
  end

  # Turns nested values' keys into delimiter separated paths
  def squish delimiter: '.'
    sh = Hash.new
    BBLib.hash_path_nav(self.dup, nil, delimiter){ |k, v| sh[k] = v }
    sh
  end

  # Expands keys in a hash using a delimiter. Opposite of squish.
  def expand **args
    eh = Hash.new
    self.dup.each do |k,v|
      eh.bridge k, args.merge({value:v})
    end
    return eh
  end

  # Add a hash path to a hash
  def bridge *path, value:nil, delimiter: '.', symbols: true, overwrite: false
    path = path.msplit(delimiter).flatten
    hash, part, bail, last = self, nil, false, nil
    while !path.empty? && !bail
      part = path.shift
      if part =~ /\A\[\d+\]\z/
        part = part[1..-2].to_i
      else
        part = part.to_sym if symbols
      end
      if (hash.is_a?(Hash) && hash.include?(part) || hash.is_a?(Array) && hash.size > part.to_i) && !overwrite
        bail = true if !hash[part].is_a?(Hash) && !hash[part].is_a?(Array)
        hash = hash[part] unless bail
      else
        hash[part] = path.first =~ /\A\[\d+\]\z/ ? Array.new : Hash.new
        hash = hash[part] unless bail || path.empty?
      end
    end
    hash[part] = value unless bail
    self
  end

end

class Array

  def hash_path *path
    BBLib.hash_path self, *path
  end

  def hash_path_set *paths
    BBLib.hash_path_set self, *paths
  end

  def hash_path_copy *paths
    BBLib.hash_path_copy self, *paths
  end

  def hash_path_copy_to to, *paths
    BBLib.hash_path_copy_to self, to, *paths
  end

  def hash_path_delete *paths
    BBLib.hash_path_delete self, *paths
  end

  def hash_path_move *paths
    BBLib.hash_path_move self, *paths
  end

  def hash_path_move_to to, *paths
    BBLib.hash_path_move_to self, to, *paths
  end

  def hash_paths
    BBLib.hash_path_keys self
  end

  def hash_path_for value
    BBLib.hash_path_key_for self, value
  end

  alias_method :hpath, :hash_path
  alias_method :hpath_set, :hash_path_set
  alias_method :hpath_move, :hash_path_move
  alias_method :hpath_move_to, :hash_path_move_to
  alias_method :hpath_delete, :hash_path_delete
  alias_method :hpath_copy, :hash_path_copy
  alias_method :hpath_copy_to, :hash_path_copy_to
  alias_method :hpaths, :hash_paths
  alias_method :hpath_for, :hash_path_for

  def dive *keys
    matches = []
    self.each do |i|
      matches+= i.dive(*keys) if i.respond_to?(:dive)
    end
    matches
  end

  # Turns nested values' keys into delimiter separated paths
  def squish delimiter: '.'
    sh = Hash.new
    BBLib.hash_path_nav(self.dup, nil, delimiter){ |k, v| sh[k] = v }
    sh
  end

  # Expands keys in a hash using a delimiter. Opposite of squish.
  def expand **args
    eh = Hash.new
    self.dup.each do |k,v|
      eh.bridge k, args.merge({value:v})
    end
    return eh
  end

end
