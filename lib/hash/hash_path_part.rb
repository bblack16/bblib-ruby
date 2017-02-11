class HashPath < BBLib::LazyClass
  class Part < BBLib::LazyClass
    attr_of [String, Regexp, Fixnum, Range], :selector, default: nil, serialize: true
    attr_str :evaluation, default: nil, allow_nil: true, serialize: true
    attr_bool :recursive, default: false, serialize: true

    def parse(path)
      evl = path.scan(/\(.*\)$/).first
      self.evaluation = evl.nil? ? nil : evl.uncapsulate('(', limit: 1)
      self.recursive = path.start_with?('[[:recursive:]]')
      self.selector = parse_selector(evl.nil? ? path : path.sub(evl, ''))
    end

    def key_match?(key, object)
      case selector
      when String
        key.to_s == selector
      when Fixnum
        key.to_i == selector
      when Range
        selector === key || object.size.times.to_a.include?(key)
      else
        selector === key
      end
    end

    def special_selector?
      selector.is_a?(String) && /^\{.*\}$/ =~ selector
    end

    def matches(object)
      matches = []
      if special_selector?
        begin
          [object.send(*selector.uncapsulate('{').split(':'))].flatten(1).compact.each do |m|
            matches << m if evaluates?(m)
          end
        rescue => e
          # Nothing, the special selector failed
          # puts e
        end
      elsif object.children?
        object.children.each do |key, value|
          matches << value if key_match?(key, object) && evaluates?(value)
          matches += matches(value) if recursive? && value.children?
        end
      end
      matches
    end

    def evaluates?(object)
      return true unless evaluation
      eval(evaluation.gsub('$', object.to_s))
    rescue => e
      # The eval resulted in an error so we return false
      false
    end

    protected

    def lazy_init(*args)
      parse(args.first) if args.first.is_a?(String)
    end

    def parse_selector(str)
      str = str.gsub('.[[:recursive:]]', '..') if str =~ /^\[\d+.*\d+\]$/
      str = str.gsub('[[:recursive:]]', '') if recursive?
      if str =~ /^\/.*\/[imx]?$/
        str.to_regex
      elsif str =~ /^\[\d+\]$/
        str.uncapsulate('[').to_i
      elsif str =~ /\[\-?\d+\.{2,3}\-?\d+\]/
        Range.new(*str.scan(/\-?\d+/).map(&:to_i))
      else
        str
      end
    end

  end
end