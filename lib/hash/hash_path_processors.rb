
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
    replace_with:     [],
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
    def self.class_based_proc(child, class_based, *methods)
      child.replace_with(
        if class_based && child.node_class == Hash
          child.value.map { |k, v| [BBLib.recursive_send(k, *methods), v] }.to_h
        elsif class_based && child.node_class == Array
          child.value.flat_map { |v| BBLib.recursive_send(v, *methods) }
        else
          BBLib.recursive_send(child.value, *methods)
        end
      )
    end

    def self.evaluate(child, *args, class_based: true)
      value = child.value
      if args.first.is_a?(String)
        child.replace_with(eval(args.first))
      else
        child.replace_with(args.first.call(value))
      end
    end

    def self.append(child, *args, class_based: true)
      class_based_proc(child, class_based, :to_s, :dup, [:concat, args.first])
    end

    def self.prepend(child, *args, class_based: true)
      class_based_proc(child, class_based, :to_s, :dup, [:prepend, args.first])
    end

    def self.split(child, *args, class_based: true)
      class_based_proc(child, class_based, [:msplit, args])
    rescue => e
      class_based_proc(child, class_based, :to_s, [:msplit, args])
    end

    def self.replace(child, *args, class_based: true)
      methods = [:to_s]
      BBLib.hash_args(*args).each { |k, v| methods << [:gsub, k, v.to_s] }
      class_based_proc(child, class_based, *methods)
    end

    def self.replace_with(child, *args, class_based: true)
      child.replace_with(args.first)
    end

    def self.extract(child, *args, class_based: true)
      class_based_proc(child, class_based, [:scan, args.first], [:[], BBLib.named_args(*args)[:slice] || (0..-1)])
    end

    def self.extract_first(child, *args, class_based: true)
      class_based_proc(child, class_based, [:scan, args.first], :first)
    end

    def self.extract_last(child, *args, class_based: true)
      class_based_proc(child, class_based, [:scan, args.first], :last)
    end

    def self.parse_date(child, *args, class_based: true)
      params = BBLib.named_args(args)
      format = params.include?(:format) ? params[:format] : '%Y-%m-%d %H:%M:%S'
      child.replace_with(
        if class_based && child.node_class == Hash
          child.value.map do |k, v|
            [_parse_date(k, args, format), v]
          end.to_h
        elsif class_based && child.node_class == Array
          child.value.map do |v|
            _parse_date(v, args, format)
          end
        else
          _parse_date(child.value, args, format)
        end
      )
    end

    def self._parse_date(value, patterns, format)
      formatted = nil
      patterns.each do |pattern|
        next unless formatted.nil?
        formatted = Time.strptime(value.to_s, pattern.to_s).strftime(format) rescue nil
      end
      formatted
    end

    def self.parse_date_unix(child, *args, class_based: true)
      child.replace_with(parse_date(child, *args, class_based: class_based).to_f)
    end

    def self.parse_duration(child, *args, class_based: true)
      class_based_proc(child, class_based, :to_s, [:parse_duration, BBLib.named_args(*args)])
    end

    def self.parse_file_size(child, *args, class_based: true)
      class_based_proc(child, class_based, :to_s, [:parse_file_size, BBLib.named_args(*args)])
    end

    def self.to_string(child, *args, class_based: true)
      class_based_proc(child, class_based, :to_s)
    end

    def self.downcase(child, *args, class_based: true)
      class_based_proc(child, class_based, :to_s, :downcase)
    end

    def self.upcase(child, *args, class_based: true)
      class_based_proc(child, class_based, :to_s, :upcase)
    end

    def self.roman(child, *args, class_based: true)
      class_based_proc(child, class_based, :to_s, (args.first == :to ? :to_roman : :from_roman))
    end

    def self.remove_symbols(child, *args, class_based: true)
      class_based_proc(child, class_based, :to_s, :drop_symbols)
    end

    def self.format_articles(child, *args, class_based: true)
      class_based_proc(child, class_based, :to_s, [:format_articles, args.first || :front])
    end

    def self.reverse(child, *args, class_based: true)
      class_based_proc(child, class_based, :reverse)
    end

    def self.delete(child, *args, class_based: true)
      child.kill
    end

    def self.remove(child, *args, class_based: true)
      methods = args.map { |a| [:gsub, a, ''] }
      methods.shift(:to_s)
      class_based_proc(child, class_based, *methods )
    end

    def self.custom(child, *args, class_based: true)
      class_based_proc(child, class_based, *args)
    end

    def self.encapsulate(child, *args, class_based: true)
      class_based_proc(child, class_based, :to_s, [:concat, args.first.to_s], [:prepend, args.first.to_s])
    end

    def self.uncapsulate(child, *args, class_based: true)
      class_based_proc(child, class_based, [:uncapsulate, args.first])
    end

    def self.max(child, *args, class_based: true)
      class_based_proc(child, class_based, :max)
    end

    def self.min(child, *args, class_based: true)
      class_based_proc(child, class_based, :min)
    end

    def self.avg(child, *args, class_based: true)
      nums = child.value.to_s.extract_numbers
      child.replace_with(nums.inject { |s, x| s + x }.to_f / nums.size.to_f)
    end

    def self.sum(child, *args, class_based: true)
      child.replace_with(value.to_s.extract_numbers.inject { |s, x| s + x })
    end

    def self.strip(child, *args, class_based: true)
      class_based_proc(child, class_based, :to_s, :strip)
    end

    def self.extract_integers(child, *args, class_based: true)
      class_based_proc(child, class_based, :to_s, :extract_integers)
    end

    def self.extract_floats(child, *args, class_based: true)
      class_based_proc(child, class_based, :to_s, :extract_floats)
    end

    def self.extract_numbers(child, *args, class_based: true)
      class_based_proc(child, class_based, :to_s, :extract_numbers)
    end

    def self.concat(child, *args, class_based: true)
      child.replace_with(([child.value] + child.root.find(args.first)).map { |v| v.to_s }.join)
    end

    def self.reverse_concat(child, *args, class_based: true)
      child.replace_with(([child.value] + child.root.find(args.first)).map { |v| v.to_s }.reverse.join)
    end
  end
end
