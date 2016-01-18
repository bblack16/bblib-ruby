module BBLib

  def self.hash_path hashes, path, recursive = false, delimiter: '.'
    return nil if !delimiter
    if delimiter.to_s.size > 1 then delimiter = delimiter[0] end
    if !path.is_a?(Array)
      if path.start_with?(delimiter) then path.sub!(delimiter, '') end
      path = BBLib.split_hash_path path, delimiter
    end
    if !hashes.is_a?(Array) then hashes = [hashes] end
    if path.nil? || path.empty? then return hashes end
    if path.first == '' then return BBLib.hash_path(hashes, path[1..-1], true) end
    current = BBLib.hash_path_analyze(path.first)
    possible = []
    hashes.each do |hash|
      if recursive
        possible << hash.dig([current[:key], current[:key].to_s]).flatten[current[:slice]]
      else # Not recursive
        if current[:key].is_a?(Symbol) || current[:key].is_a?(String)
          if current[:key].to_s == '*'
            possible << hash.values.flatten[current[:slice]]
          else
            possible << [(hash[current[:key]] ||= hash[current[:key].to_s])].flatten[current[:slice]]
          end
        else
          hash.keys.map{ |k| k =~ current[:key] }.each do |m|
            if m then possible << hash[m].flatten[current[:slice]] end
          end
        end
      end
    end
    # Analyze formulas if necessary
    if current[:formula]
      temp = []
      possible.flatten.each do |p|
        if current[:formula]
          begin
            if eval(current[:formula].gsub('$', p.to_s))
              temp << p
            end
          rescue StandardError, SyntaxError => se
            # Do nothing, the formula failed and we reject the value as a false
          end
        end
      end
      possible = temp
    end
    # Move on or return the results if no more paths exist
    if path.size > 1 && !possible.empty?
      BBLib.hash_path(possible.flatten.reject{ |r| !r.is_a?(Hash) }, path[1..-1])
    else
      return possible
    end
  end

  private

    def self.hash_path_analyze path
      key = path.scan(/\A.*^[^\[\(\{]*/i).first.to_s
      if key.encap_by?('/') then key = eval(key) else key = key.to_sym end
      slice = eval(path.scan(/(?<=\[).*(?=\])/).first.to_s)
      if slice.nil? then slice = (0..-1) end
      formula = path.scan(/(?<=\().*(?=\))/).first
      {key:key, slice:slice, formula:formula}
    end

    def self.split_hash_path path, delimiter = '.'
      paths = []
      stop = 0
      open = false
      path.chars.each do |t|
        if t == '[' then open = true end
        if t == ']' then open = false end
        if t == delimiter && !open then paths << path[0..stop].reverse.sub(delimiter,'').reverse; path = path[stop+1..-1]; stop = -1 end
        stop += 1
      end
      paths << path
    end

end



class Hash

  def hash_path path, delimiter: '.'
    BBLib.hash_path self, path, delimiter:delimiter
  end

end
