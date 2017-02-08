# frozen_string_literal: true
require 'time'

module BBLib
  class HashPathProc < BBLib::LazyClass
    attr_ary_of String, :paths, default: [], serialize: true, uniq: true
    attr_of [String, Symbol], :action, default: nil, allow_nil: true, serialize: true, pre_proc: proc { |a| HashPathProc.map_action(a.to_sym) }
    attr_ary_of Object, :args, default: [], serialize: true
    attr_hash :options, default: {}, serialize: true
    attr_str :condition, default: nil, allow_nil: true, serialize: true
    attr_bool :recursive, default: false, serialize: true

    def process(hash)
      return hash unless @action
      paths.each do |path|
        hash.hpath(path).each do |value|
          if condition
            begin
              next unless eval(condition.gsub('$', value.to_s))
            rescue => e
              next
            end
          end
          if recursive && (hash.is_a?(Hash) || hash.is_a?(Array))
            hash.squish.keys.each do |sub_path|
              value = hash.hpath(sub_path).first
              HashPathProcs.send(find_action(action), hash, sub_path, value, *full_args)
            end
          else
            HashPathProcs.send(find_action(action), hash, path, value, *full_args)
          end
        end
      end
      hash
    end

    protected
    USED_KEYWORDS = [:action, :args, :paths, :recursive]

    def find_action(action)
      (HashPathProcs.respond_to?(action) ? action : :custom)
    end

    def full_args
      (HASH_PATH_PROC_TYPES.include?(action) ? [] : [action]) +
      args +
      (options.empty? || options.nil? ? [] : [options])
    end

    def self.map_action(action)
      clean = HASH_PATH_PROC_TYPES.find { |k, v| action == k || v.include?(action) }
      clean ? clean.first : action
    end

    def lazy_init(*args)
      options = BBLib.named_args(*args)
      options.merge(options.delete(:options)) if options[:options]
      USED_KEYWORDS.each { |k| options.delete(k) }
      self.options = options
      self.paths += args.find_all { |a| a.is_a?(String) }
      self.action = args.first if args.first.is_a?(Symbol) && @action.nil?
    end
  end
end

class Hash
  def hash_path_proc(*args)
    BBLib.hash_path_proc(self, *args)
  end

  alias hpath_proc hash_path_proc
end

class Array
  def hash_path_proc(*args)
    BBLib.hash_path_proc(self, *args)
  end

  alias hpath_proc hash_path_proc
end

module BBLib
  def self.hash_path_proc(hash, *args)
    HashPathProc.new(*args).process(hash)
  end

  HASH_PATH_PROC_TYPES = {
    evaluate:         [:eval, :equation, :equate],
    append:           [:suffix],
    prepend:          [:prefix],
    split:            [:delimit, :delim, :separate, :msplit],
    replace:          [:swap],
    extract:          [:grab, :scan],
    extract_first:    [:grab_first, :scan_first],
    extract_last:     [:grab_last, :scan_last],
    parse_date:       [:date, :parse_time, :time],
    parse_date_unix:  [:unix_time, :unix_date],
    parse_duration:   [:duration],
    parse_file_size:  [:file_size],
    to_string:        [:to_s, :stringify],
    downcase:         [:lower, :lowercase, :to_lower],
    upcase:           [:upper, :uppercase, :to_upper],
    roman:            [:convert_roman, :roman_numeral, :parse_roman],
    remove_symbols:   [:chop_symbols, :drop_symbols],
    format_articles:  [:articles],
    reverse:          [:invert],
    delete:           [:del],
    remove:           [:rem],
    custom:           [:send],
    encapsulate:      [],
    uncapsulate:      [],
    extract_integers: [:extract_ints, :extract_i],
    extract_floats:   [:extract_f],
    extract_numbers:  [:extract_nums],
    max_number:       [:max, :maximum, :maximum_number],
    min_number:       [:min, :minimum, :minimum_number],
    avg_number:       [:avg, :average, :average_number],
    sum_number:       [:sum],
    strip:            [:trim],
    concat:           [:join, :concat_with],
    reverse_concat:   [:reverse_join, :reverse_concat_with]
  }.freeze

  module HashPathProcs
    def self.evaluate(hash, path, value, args)
      exp = args.to_a.first.to_s.gsub('$', value.to_s)
      hash.hash_path_set path => eval(exp)
    end

    def self.append(hash, path, value, args)
      hash.hash_path_set path => "#{value}#{args}"
    end

    def self.prepend(hash, path, value, args)
      hash.hash_path_set path => "#{args}#{value}"
    end

    def self.split(hash, path, value, *args)
      hash.hash_path_set path => value.msplit(args)
    end

    def self.replace(hash, path, value, args)
      value = value.dup.to_s
      args.each { |k, v| value.gsub!(k, v.to_s) }
      hash.hash_path_set path => value
    end

    def self.extract(hash, path, value, *args)
      slice = (Array === args && args[1].nil? ? (0..-1) : args[1])
      hash.hash_path_set path => value.to_s.scan(args.first)[slice]
    end

    def self.extract_first(hash, path, value, *args)
      extract(hash, path, value, *args + [0])
    end

    def self.extract_last(hash, path, value, *args)
      extract(hash, path, value, *args + [-1])
    end

    def self.parse_date(hash, path, value, *args)
      params = BBLib.named_args(args)
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
        formatted = Time.parse(value) if formatted.nil?
      rescue
      end
      hash.hash_path_set path => formatted
    end

    def self.parse_date_unix(hash, path, value, *args)
      params = BBLib.named_args(args)
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
        formatted = Time.parse(value) if formatted.nil?
      rescue
      end
      hash.hash_path_set path => formatted.to_f
    end

    def self.parse_duration(hash, path, value, args)
      hash.hash_path_set path => value.to_s.parse_duration(output: args.empty? ? :sec : args)
    end

    def self.parse_file_size(hash, path, value, args)
      hash.hash_path_set path => value.to_s.parse_file_size(output: args.empty? ? :bytes : args)
    end

    def self.to_string(hash, path, value, *_args)
      hash.hash_path_set path => value.to_s
    end

    def self.downcase(hash, path, value, *_args)
      hash.hash_path_set path => value.to_s.downcase
    end

    def self.upcase(hash, path, value, *_args)
      hash.hash_path_set path => value.to_s.upcase
    end

    def self.roman(hash, path, value, *args)
      hash.hash_path_set path => (args[0] == :to ? value.to_s.to_roman : value.to_s.from_roman)
    end

    def self.remove_symbols(hash, path, value, *_args)
      hash.hash_path_set path => value.to_s.drop_symbols
    end

    def self.format_articles(hash, path, value, args)
      hash.hash_path_set path => value.to_s.move_articles(args.nil? ? :front : args)
    end

    def self.reverse(hash, path, value, *_args)
      hash.hash_path_set path => value.to_s.reverse
    end

    def self.delete(hash, path, _value, *_args)
      hash.hash_path_delete path
    end

    def self.remove(hash, path, value, *args)
      removed = value.to_s
      args.each { |a| removed.gsub!(a, '') }
      hash.hash_path_set path => removed
    end

    def self.custom(hash, path, value, *args)
      hash.hash_path_set path => value.send(*args)
    end

    def self.encapsulate(hash, path, value, args)
      hash.hash_path_set path => "#{args}#{value}#{args}"
    end

    def self.uncapsulate(hash, path, value, args)
      value = value[args.size..-1] if value.start_with?(args)
      value = value[0..-args.size-1] if value.end_with?(args)
      hash.hash_path_set path => value
    end

    def self.max_number(hash, path, value, *_args)
      hash.hash_path_set path => value.to_s.extract_numbers.max
    end

    def self.min_number(hash, path, value, *_args)
      hash.hash_path_set path => value.to_s.extract_numbers.min
    end

    def self.avg_number(hash, path, value, *_args)
      nums = value.to_s.extract_numbers
      avg = nums.inject { |s, x| s + x }.to_f / nums.size.to_f
      hash.hash_path_set path => avg
    end

    def self.sum_number(hash, path, value, *_args)
      hash.hash_path_set path => value.to_s.extract_numbers.inject { |s, x| s + x }
    end

    def self.strip(hash, path, value, *_args)
      value.map! { |m| m.respond_to?(:strip) ? m.strip : m } if value.is_a?(Array)
      hash.hash_path_set path => (value.respond_to?(:strip) ? value.strip : value)
    end

    def self.extract_integers(hash, path, value, *_args)
      hash.hash_path_set path => value.extract_integers
    end

    def self.extract_floats(hash, path, value, *_args)
      hash.hash_path_set path => value.extract_floats
    end

    def self.extract_numbers(hash, path, value, *_args)
      hash.hash_path_set path => value.extract_numbers
    end

    def self.concat(hash, path, value, *args)
      params = BBLib.named_args(args)
      hash.hash_path_set path => "#{value}#{params[:join]}#{hash.hash_path(args.first)[params[:range].nil? ? 0 : params[:range]]}"
    end

    def self.reverse_concat(hash, path, value, *args)
      params = BBLib.named_args(args)
      hash.hash_path_set path => "#{hash.hash_path(args.first)[params[:range].nil? ? 0 : params[:range]]}#{params[:join]}#{value}"
    end
  end
end
