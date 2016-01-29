module BBLib

  def self.hash_path hashes, path, recursive: false, delimiter: '.', symbol_sensitive: false
    if String === path then path = BBLib.split_and_analyze(path, delimiter) end
    if !hashes.is_a? Array then hashes = [hashes] end
    return hashes if path.nil? || path.empty?
    # puts path[0]
    if path[0][:key] == '' then return BBLib.hash_path(hashes, path[1..-1], recursive: true, symbol_sensitive:symbol_sensitive) end
    # puts "STILL GOING #{recursive} #{hashes}"
    matches, p = Array.new, path.first
    hashes.each do |hash|
      if recursive
        patterns = Regexp === p[:key] ? p[:key] : p[:key].to_s == '*' ? /.*/ : (symbol_sensitive ? p[:key] : [p[:key].to_sym, p[:key].to_s])
        matches.push hash.dig(patterns).flatten(1)[p[:slice]]
      else
        if p[:key].nil?
          # puts "HURRAY"
          if hash.is_a?(Array) then matches << hash[p[:slice]] end
        elsif Symbol === p[:key] || String === p[:key]
          # puts "noo...."
          if p[:key].to_s == '*'
            matches.push hash.values.flatten(1)[p[:slice]]
          else
            next unless symbol_sensitive ? hash.include?(p[:key]) : (hash.include?(p[:key].to_sym) || hash.include?(p[:key].to_s) )
            mat = (symbol_sensitive ? hash[p[:key]] : (hash[p[:key].to_sym] ||= hash[p[:key].to_s]))
            matches.push mat.is_a?(Array) ? mat[p[:slice]] : mat
            # puts "M #{matches}"
          end
        elsif Regexp === p[:key]
          hash.keys.find_all{ |k| k =~ p[:key] }.each{ |m| matches << hash[m] }
        end
      end
    end
    matches = BBLib.analyze_hash_path_formula p[:formula], matches
    if path.size > 1 && !matches.empty?
      # p "MAT #{matches}"
      # matches.map!{ |m| m.is_a?(Array) ? [m] : m }
      BBLib.hash_path(matches.reject{ |r| !(r.is_a?(Hash) || r.is_a?(Array)) }, path[1..-1], symbol_sensitive:symbol_sensitive)
    else
      return matches.flatten(1)
    end
  end

  def self.hash_path_set hash, *args
    details = BBLib.hash_path_setup(hash, args)
    count = 0
    details[:paths].each do |path, d|
      d[:hashes].each do |h|
        count+=1
        exists = (details[:symbol_sensitive] ? h.include?(d[:last][:key]) : (h.include?(d[:last][:key].to_sym) || h.include?(d[:last][:key].to_s) ))
        next unless details[:bridge] || exists
        key = details[:symbol_sensitive] ? d[:last][:key] : (h.include?(d[:last][:key].to_sym) ? d[:last][:key].to_sym : d[:last][:key].to_s)
        if details[:symbols] then key = key.to_sym elsif !exists then key = d[:last][:key] end
        if Fixnum === d[:last][:slice]
          h[key][d[:last][:slice]] = d[:value]
        else
          if h.is_a?(Hash)
            h[key] = d[:value]
          end
        end
      end
      if count == 0 && details[:bridge] then hash.bridge(path, value:d[:value], symbols:details[:symbols]) end
    end
    hash
  end

  def self.hash_path_exists? hash, path, delimiter: '.', symbol_sensitive: false
    return !BBLib.hash_path(hash, path, delimiter:delimiter, symbol_sensitive:symbol_sensitive).empty?
  end

  def self.hash_path_move hash, *args
    BBLib.hash_path_copy hash, args
    details = BBLib.hash_path_setup(hash, args)
    opts = Hash.new
    details.each do |k, v|
      if HASH_PATH_PARAMS.include?(k) then opts[k] = v end
    end
    BBLib.hash_path_delete hash, [details[:paths].keys, opts ].flatten
    return hash
  end

  def self.hash_path_move_to from, to, *args
    BBLib.hash_path_copy_to from, to, args
    BBLib.hash_path_delete from, args
    return to
  end

  def self.hash_path_copy hash, *args
    details = BBLib.hash_path_setup(hash, args)
    details[:paths].each do |path, d|
      d[:hashes].each do |h|
        if Hash === h || Array === h
          exist = details[:symbol_sensitive] ? h.include?(d[:last][:key]) : (h.include?(d[:last][:key].to_sym) || h.include?(d[:last][:key].to_s) )
          next unless exist || details[:bridge]
          value = details[:symbol_sensitive] ? h[d[:last][:key]] : (h[d[:last][:key].to_sym] ||= h[d[:last][:key].to_s])
          if value
            BBLib.hash_path_set hash, d[:value] => value, symbols:details[:symbols]
          end
        elsif !details[:stop_on_nil]
          BBLib.hash_path_set hash, d[:value] => nil, symbols:details[:symbols]
        end
      end
    end
    hash
  end

  def self.hash_path_copy_to from, to, *args
    details = BBLib.hash_path_setup(from, args)
    details[:paths].each do |path, d|
      value = from.hash_path(path)
      if !value.empty? || !details[:stop_on_nil]
        if !details[:arrays].include?(d[:value]) then value = value.first end
        to = to.bridge(d[:value], value: value, symbols:details[:symbols])
      end
    end
    to
  end

  def self.hash_path_delete hash, *args
    args.flatten!
    details = BBLib.hash_path_setup hash, [args.find{ |f| Hash === f }.to_h.merge(args.find_all{ |a| String === a }.zip([]).to_h)]
    deleted = []
    details[:paths].each do |path, d|
      d[:hashes].each do |h|
        next unless details[:symbol_sensitive] ? h.include?(d[:last][:key]) : (h.include?(d[:last][:key].to_sym) || h.include?(d[:last][:key].to_s) )
        if Fixnum === d[:last][:slice]
          (details[:symbol_sensitive] ? h[d[:last][:key]] : (h[d[:last][:key].to_sym] ||= h[d[:last][:key].to_s] )).delete_at d[:last][:slice]
        else
          if details[:symbol_sensitive]
            deleted << h.delete(d[:last][:key])
          else
            if h.include?(d[:last][:key].to_sym) then deleted << h.delete(d[:last][:key].to_sym) end
            if h.include?(d[:last][:key].to_s) then deleted << h.delete(d[:last][:key].to_s) end
          end
        end
      end
    end
    return deleted.flatten
  end

  def self.hash_path_keys hash
    hash.squish.keys
  end

  def self.hash_path_key_for hash, value
    hash.squish.find_all{ |k,v| v == value }.to_h.keys
  end

  def self.path_nav obj, path = '', delimiter = '.', &block
    case [obj.class]
    when [Hash]
      obj.each{ |k,v| path_nav v, "#{path}#{path.nil? || path.empty? ? nil : delimiter}#{k}", delimiter, &block }
    when [Array]
      index = 0
      obj.each{ |o| path_nav o, "#{path}#{path.end_with?(']') ? delimiter : nil}[#{index}]", delimiter, &block ; index+=1 }
    else
      yield path, obj
    end
  end

  private

    def self.hash_path_analyze path
      key = path.scan(/\A.*^[^\[\(\{]*/i).first.to_s
      if key.encap_by?('/')
        key = eval(key)
      elsif key.start_with? ':'
        key = key[1..-1].to_sym
      end
      slice = eval(path.scan(/(?<=\[).*?(?=\])/).first.to_s)
      if slice.nil? then slice = (0..-1) end
      formula = path.scan(/(?<=\().*?(?=\))/).first
      if key.empty? && slice != (0..-1) then key = nil end
      {key:key, slice:slice, formula:formula}
    end

    def self.split_hash_path path, delimiter = '.'
      if path.to_s.start_with?(delimiter) then path = path.to_s.sub(delimiter, '') end
      paths, stop, open = [], 0, false
      path.chars.each do |t|
        if t == '[' then open = true end
        if t == ']' then open = false end
        if t == delimiter && !open then paths << path[0..stop].reverse.sub(delimiter,'').reverse; path = path[stop+1..-1]; stop = -1 end
        stop += 1
      end
      paths << path
    end

    def self.split_and_analyze path, delimiter = '.'
      split_hash_path(path, delimiter).collect{ |p| hash_path_analyze(p) }
    end

    def self.analyze_hash_path_formula formula, hashes
      return hashes unless formula
      temp = []
      hashes.flatten.each do |p|
        begin
          if eval(formula.gsub('$', p.to_s))
            temp << p
          end
        rescue StandardError, SyntaxError => se
          # Do nothing, the formula failed and we reject the value as a false
        end
      end
      temp
    end

    def self.hash_path_setup hash, *args
      args.flatten!
      return nil unless args && args[0].class == Hash
      info = Hash.new
      info[:paths] = Hash.new
      map = args[0].dup
      HASH_PATH_PARAMS.each do |p, h|
        info[p] = (map.include?(p) ? map.delete(p) : h[:default])
      end
      if info[:keys_to_sym] then hash.keys_to_sym! end
      map.each do |path, value|
        info[:paths][path] = Hash.new
        info[:paths][path][:value] = value
        info[:paths][path][:paths] = BBLib.split_hash_path(path, info[:delimiter])
        info[:paths][path][:last] = BBLib.hash_path_analyze info[:paths][path][:paths].last
        info[:paths][path][:hashes] = BBLib.hash_path(hash, info[:paths][path][:paths][0..-2].join(info[:delimiter]), delimiter:info[:delimiter], symbol_sensitive:info[:symbol_sensitive] )
      end
      return info
    end

    HASH_PATH_PARAMS = {
      delimiter: {default:'.'},
      bridge: {default:true},
      symbols: {default:true},
      symbol_sensitive: {default:false},
      stop_on_nil: {default:true},
      arrays: {default:[]},
      keys_to_sym: {default:true}
    }

end



class Hash

  def hash_path path, delimiter: '.'
    BBLib.hash_path self, path, delimiter:delimiter
  end

  def hash_path_set *args
    BBLib.hash_path_set self, args
  end

  def hash_path_copy *args
    BBLib.hash_path_copy self, args
  end

  def hash_path_copy_to hash, *args
    BBLib.hash_path_copy_to self, hash, args
  end

  def hash_path_move_to hash, *args
    BBLib.hash_path_move_to self, hash, args
  end

  def hash_path_move *args
    BBLib.hash_path_move self, args
  end

  def hash_path_delete *args
    BBLib.hash_path_delete self, args
  end

  def hash_path_keys
    BBLib.hash_path_keys self
  end

  def hash_path_exists? path, delimiter: '.', symbol_sensitive: false
    BBLib.hash_path_exists? self, path, delimiter:delimiter, symbol_sensitive:symbol_sensitive
  end

  # Returns all matching values with a specific key (or Array of keys) recursively within a Hash (including nested Arrays)
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

  # Turns nested values' keys into delimiter separated paths
  def squish delimiter: '.', path_start: nil
    sh = Hash.new
    BBLib.path_nav(self.dup, path_start, delimiter){ |k, v| sh[k] = v }
    sh
  end

  # Expands keys in a hash using a delimiter. Opposite of squish.
  def expand delimiter: '.', symbols: false
    eh = Hash.new
    self.dup.each do |k,v|
      eh.bridge k, delimiter: delimiter, value:v, symbols: true
    end
    return eh
  end

  # Builds out a shell of a hash path using a delimited path. Use value to set a value.
  def bridge path, delimiter: '.', value: nil, symbols: false
    # Ensure the path is a delimiter string. This supports arrays being passed in
    path = (path.is_a?(Array) ? path.join(delimiter) : path.to_s)
    #Generate the paths and set the current variable
    current, paths = self, BBLib.split_and_analyze(path, delimiter)
    # If symbols is true, then all keys are turned into symbols
    if symbols then paths.each{ |p| p[:key] = p[:key].to_s.to_sym } end
    # Check to see if there is only one path. If there is return either an Array of Hash
    if paths.size == 1
      # If the first value is a slice the value is inserted into an empty array
      if Fixnum === paths.first[:slice]
        current[paths.first[:key]] = ([].insert paths.first[:slice], value )
        return self
      end
      # If the value does not have a slice, a hash with a single key-value pair is returned
      current[paths.first[:key]] = value
      return self
    end
    index, count = -1, 0
    paths.each do |p|
      count+=1
      last = paths.size == count
      if p[:slice].is_a?(Fixnum)
        index = p[:slice]
        if paths[count-2] && Fixnum === paths[count-2][:slice]
          current[paths[count-2][:slice]] = current[paths[count-2][:slice]] ||= Array.new
          current = current[paths[count-2][:slice]]
        else
          if current[p[:key]].nil?
            current[p[:key]] = []
          end
            current = current[p[:key]]
        end
        if last then current[index] = value end
      else
        if current.is_a?(Hash)
          if last
            current[p[:key]] = value
          else
            current[p[:key]] = current[p[:key]] ||= Hash.new
          end
          current = current[p[:key]]
        else
          if last
            if current[index]
              if current[index].is_a? Hash
                current[index].merge({p[:key] => value})
              else
                current[index] = ({p[:key] => value})
              end
            else
              current.insert index, {p[:key] => value}
            end
          else
            temp = { p[:key] => {} }
            if current[index].is_a? Hash
              current[index].merge!(temp)
            else
              current[index] = temp
            end
          end
          if !last then current = temp[p[:key]] end
        end
        index = -1
      end
    end
    return self
  end

end
