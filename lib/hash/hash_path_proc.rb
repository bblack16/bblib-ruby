require 'time'

class Hash
  def hash_path_proc action, paths, *args, **params
    BBLib.hash_path_proc self, action, paths, *args, **params
  end
end

module BBLib

  def self.hash_path_proc hash, action, paths, *args, **params
    action = HASH_PATH_PROC_TYPES.keys.find{ |k| k == action || HASH_PATH_PROC_TYPES[k][:aliases].include?(action) }
    return nil unless action
    paths.to_a.each do |path|
      hash.hash_path(path).each do |value|
        if params.include?(:condition) && params[:condition]
          begin
            next unless eval(params[:condition].gsub('$', value.to_s))
          rescue
            next
          end
        end
        HashPath.send(action, hash, path, value, *args, **params)
      end
    end
    return hash
  end

  HASH_PATH_PROC_TYPES = {
    evaluate: { aliases: [:eval, :equation, :equate]},
    append: { aliases: [:suffix]},
    prepend: { aliases: [:prefix]},
    split: { aliases: [:delimit, :delim, :separate, :msplit]},
    replace: { aliases: [:swap]},
    extract: { aliases: [:grab, :scan]},
    extract_first: {aliases: [:grab_first, :scan_first]},
    extract_last: {aliases: [:grab_last, :scan_last]},
    parse_date: { aliases: [:date, :parse_time, :time]},
    parse_duration: { aliases: [:duration]},
    parse_file_size: { aliases: [:file_size]},
    to_string: {aliases: [:to_s, :stringify]},
    downcase: { aliases: [:lower, :lowercase, :to_lower]},
    upcase: { aliases: [:upper, :uppercase, :to_upper]},
    roman: { aliases: [:convert_roman, :roman_numeral, :parse_roman]},
    remove_symbols: { aliases: [:chop_symbols, :drop_symbols]},
    format_articles: { aliases: [:articles]},
    reverse: { aliases: [:invert]},
    delete: { aliases: [:del]},
    remove: { aliases: [:rem]},
    custom: {aliases: [:send]},
    # TODO
    # titlecase: { aliases: [:title_case]},
    encapsulate: {aliases: []},
    uncapsulate: {aliases: []},
    extract_integers: {aliases: [:extract_ints]},
    extract_floats: {aliases: []},
    extract_numbers: {aliases: []},
    max_number: {aliases: [:max, :maximum, :maximum_number]},
    min_number: {aliases: [:min, :minimum, :minimum_number]},
    avg_number: {aliases: [:avg, :average, :average_number]},
    sum_number: {aliases: [:sum]},
    strip: {aliases: [:trim]},
    # rename: { aliases: [:rename_key]},
    # concat: { aliases: [:join, :concat_with]},
    # reverse_concat: { aliases: [:reverse_join, :reverse_concat_with]}
  }

  module HashPath

    def self.evaluate hash, path, value, args, params
      exp = args.to_a.first.to_s.gsub('$', value.to_s)
      hash.hash_path_set path => eval(exp)
    end

    def self.append hash, path, value, args, params
      hash.hash_path_set path => "#{value}#{args}"
    end

    def self.prepend hash, path, value, args, params
      hash.hash_path_set path => "#{args}#{value}"
    end

    def self.split hash, path, value, args, params
      hash.hash_path_set path => value.msplit(args)
    end

    def self.replace hash, path, value, args, params
      value = value.dup.to_s
      args.each{ |k,v| value.gsub!(k, v.to_s) }
      hash.hash_path_set path => value
    end

    def self.extract hash, path, value, *args, **params
      slice = (Array === args && args[1].nil? ? (0..-1) : args[1])
      hash.hash_path_set path => value.scan(args.first)[slice]
    end

    def self.extract_first hash, path, value, *args, **params
      extract(hash, path, value, *args + [0])
    end

    def self.extract_last hash, path, value, *args, **params
      extract(hash, path, value, *args + [-1])
    end

    def self.parse_date hash, path, value, *args, **params
      format = params.include?(:format) ? params[:format] : '%Y-%m-%d %H:%M:%S'
      formatted = nil
      args.each do |pattern|
        next unless formatted.nil?
        begin
          formatted = Time.strptime(value.to_s, pattern.to_s).strftime(format)
        rescue
        end
      end
      begin
        if formatted.nil? then formatted = Time.parse(value) end
      rescue
      end
      hash.hash_path_set path => formatted
    end

    def self.parse_duration hash, path, value, args, params
      hash.hash_path_set path => value.to_s.parse_duration(output: args.empty? ? :sec : args )
    end

    def self.parse_file_size hash, path, value, args, params
      hash.hash_path_set path => value.to_s.parse_file_size(output: args.empty? ? :bytes : args )
    end

    def self.to_string hash, path, value, *args, **params
      hash.hash_path_set path => value.to_s
    end

    def self.downcase hash, path, value, *args, **params
      hash.hash_path_set path => value.to_s.downcase
    end

    def self.upcase hash, path, value, *args, **params
      hash.hash_path_set path => value.to_s.upcase
    end

    def self.roman hash, path, value, *args, **params
      hash.hash_path_set path => (args[0] == :to ? value.to_s.to_roman : value.to_s.from_roman)
    end

    def self.remove_symbols hash, path, value, *args, **params
      hash.hash_path_set path => value.to_s.drop_symbols
    end

    def self.format_articles hash, path, value, args, **params
      hash.hash_path_set path => value.to_s.move_articles(args.nil? ? :front : args)
    end

    def self.reverse hash, path, value, *args, **params
      hash.hash_path_set path => value.to_s.reverse
    end

    def self.delete hash, path, value, *args, **params
      hash.hash_path_delete path
    end

    def self.remove hash, path, value, *args, **params
      removed = value.to_s
      args.each{ |a| removed.gsub!(a, '')}
      hash.hash_path_set path => removed
    end

    def self.custom hash, path, value, *args, **params
      hash.hash_path_set path => value.send(*args)
    end

    def self.encapsulate hash, path, value, args, **params
      hash.hash_path_set path => "#{args}#{value}#{args}"
    end

    def self.uncapsulate hash, path, value, args, **params
      value = value[args.size..-1] if value.start_with?(args)
      value = value[0..-(args.size)-1] if value.end_with?(args)
      hash.hash_path_set path => value
    end

    def self.max_number hash, path, value, *args, **params
      hash.hash_path_set path => value.to_s.extract_numbers.max
    end

    def self.min_number hash, path, value, *args, **params
      hash.hash_path_set path => value.to_s.extract_numbers.min
    end

    def self.avg_number hash, path, value, *args, **params
      nums = value.to_s.extract_numbers
      avg = nums.inject{ |s, x| s + x }.to_f / nums.size.to_f
      hash.hash_path_set path => avg
    end

    def self.sum_number hash, path, value, *args, **params
      hash.hash_path_set path => value.to_s.extract_numbers.inject{ |s,x| s + x }
    end

    def self.strip hash, path, value, args, **params
      hash.hash_path_set path => (value.respond_to?(:strip) ? value.strip : value)
    end

    def self.extract_integers hash, path, value, args, **params
      hash.hash_path_set path => (value.extract_integers)
    end

    def self.extract_floats hash, path, value, args, **params
      hash.hash_path_set path => (value.extract_floats)
    end

    def self.extract_numbers hash, path, value, args, **params
      hash.hash_path_set path => (value.extract_numbers)
    end

  end

end
