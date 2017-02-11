
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
    def self.evaluate(child, *args)
      child.replace_with(eval(args.first.to_s.gsub('$', 'child.value')))
    end

    def self.append(child, *args)
      child.replace_with("#{child.value}#{args.first}")
    end

    def self.prepend(child, *args)
      child.replace_with("#{args.first}#{child.value}")
    end

    def self.split(child, *args)
      child.replace_with(child.value.msplit(*args))
    end

    def self.replace(child, *args)
      BBLib.named_args.each { |k, v| child.replace_with(child.value.to_s.gsub(k, v.to_s)) }
    end

    def self.extract(child, *args)
      child.replace_with(child.value.scan(args.first)[BBLib.named_args[:slice] || (0..-1)])
    end

    def self.extract_first(child, *args)
      child.replace_with(extract(child, *args).first)
    end

    def self.extract_last(child, *args)
      child.replace_with(extract(child, *args).last)
    end

    def self.parse_date(child, *args)
      params = BBLib.named_args(args)
      format = params.include?(:format) ? params[:format] : '%Y-%m-%d %H:%M:%S'
      formatted = nil
      args.each do |pattern|
        next unless formatted.nil?
        formatted = Time.strptime(child.value.to_s, pattern.to_s).strftime(format) rescue nil
      end
      (formatted = Time.parse(child.value) if formatted.nil? )rescue nil
      child.replace_with(formatted)
    end

    def self.parse_date_unix(child, *args)
      child.replace_with(parse_date(child, *args).to_f)
    end

    def self.parse_duration(child, *args)
      child.replace_with(child.value.to_s.parse_duration(*args))
    end

    def self.parse_file_size(child, *args)
      child.replace_with(child.value.to_s.parse_file_size(*args))
    end

    def self.to_string(child, *args)
      child.replace_with(child.value.to_s)
    end

    def self.downcase(child, *args)
      child.replace_with(child.value.to_s.downcase)
    end

    def self.upcase(child, *args)
      child.replace_with(child.value.to_s.upcase)
    end

    def self.roman(child, *args)
      child.replace_with(args.first == :to ? child.value.to_s.to_roman : child.value.to_s.from_roman)
    end

    def self.remove_symbols(child, *args)
      child.replace_with(child.value.to_s.drop_symbols)
    end

    def self.format_articles(child, *args)
      child.replace_with(child.value.to_s.move_articles(*args))
    end

    def self.reverse(child, *args)
      child.replace_with(child.value.respond_to?(:reverse) ? child.value.reverse : child.value.to_s.reverse)
    end

    def self.delete(value, *args)
      child.kill
    end

    def self.remove(child, *args)
      args.each { |a| child.replace_with(child.value.gsub(a, '')) }
    end

    def self.custom(child, *args)
      child.replace_with(child.value.send(*args))
    end

    def self.encapsulate(child, *args)
      child.replace_with("#{args}#{child.value}#{args}")
    end

    def self.uncapsulate(child, *args)
      child.replace_with(child.value.uncapsulate(*args))
    end

    def self.max(child, *args)
      child.replace_with(child.value.respond_to?(:max) ? child.value.max : child.value.to_s.extract_numbers.max)
    end

    def self.min(child, *args)
      child.replace_with(child.value.respond_to?(:min) ? child.value.min : child.value.to_s.extract_numbers.min)
    end

    def self.avg(child, *args)
      nums = child.value.to_s.extract_numbers
      child.replace_with(nums.inject { |s, x| s + x }.to_f / nums.size.to_f)
    end

    def self.sum(child, *args)
      child.replace_with(value.to_s.extract_numbers.inject { |s, x| s + x })
    end

    def self.strip(child, *args)
      child.replace_with(
        case [child.node_class]
        when [Hash]
          child.value.map { |k, v| [k, v.to_s.strip] }.to_h
        when [Array]
          child.value.map { |x| x.to_s.strip }
        else
          child.to_s.strip
        end
      )
    end

    def self.extract_integers(child, *args)
      child.replace_with(child.value.to_s.extract_integers)
    end

    def self.extract_floats(child, *args)
      child.replace_with(child.value.to_s.extract_floats)
    end

    def self.extract_numbers(child, *args)
      child.replace_with(child.value.to_s.extract_numbers)
    end

    def self.concat(child, *args)
      child.replace_with(([child.value] + child.root.find(args.first)).map { |v| v.to_s }.join)
    end

    def self.reverse_concat(child, *args)
      child.replace_with(([child.value] + child.root.find(args.first)).map { |v| v.to_s }.reverse.join)
    end
  end
end
