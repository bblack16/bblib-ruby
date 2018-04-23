module BBLib
  class Splitter
    include BBLib::Effortless

    attr_hash :expressions, required: true, pre_proc: :process_expressions
    attr_ary_of [String, Regexp], :delimiters, required: true

    attr_bool :inside, default: false
    attr_int :current_start, :current_depth, default: 0
    attr_of [String, Symbol, Regexp], :current_expression, allow_nil: true
    attr_str :current_match, :current_delimiter_match, :current_expression_match, allow_nil: true, default: nil
    attr_str :part, default: ''
    attr_bool :ignore_escaped_chars, default: true
    attr_bool :escaped, default: false
    attr_str :escape_char, default: '\\'

    def self.split(string, *delimiters, **opts)
      new(opts.except(:count).merge(delimiters: delimiters)).split(string, opts.delete(:count))
    end

    def split(string, count = nil)
      return string if count == 1
      index = 0
      splits = 1
      [].tap do |array|
        until index >= string.size
          sub_string = string[index..-1]
          escaped    = string[index - 1] == escape_char if ignore_escaped_chars?

          if inside?
            open_match = match(sub_string, current_expression)
            close_match = match(sub_string, expressions[current_expression])
            if current_start != index && close_match && !escaped
              self.inside = false if (self.current_depth -= 1).zero?
            elsif open_match && !escaped
              self.current_depth += 1
              self.part += open_match
              index += open_match.size
              next
            end
          elsif expression = check_expressions(sub_string)
            self.inside = true
            self.current_start = index
            self.current_expression = expression
            self.current_depth += 1
            self.part += current_expression_match
            index += current_expression_match.size
            next
          elsif !escaped? && (count.nil? || splits < count) && delimiter_check(sub_string)
            array << self.part
            splits += 1
            self.part = ''
            index += current_delimiter_match.size
            next
          end
          self.part += string[index].to_s
          index += 1
        end
        array << self.part
      end
    end

    protected

    def match(sub_string, expression)
      case expression
      when Regexp
        (sub_string =~ expression)&.zero? ? sub_string.scan(expression).first : nil
      when String, Symbol
        sub_string.start_with?(expression.to_s) ? expression.to_s : nil
      else
        nil
      end
    end

    def check_expressions(sub_string)
      expressions.find do |open_expression, _close_expression|
        self.current_expression_match = match(sub_string, open_expression)
      end&.first
    end

    def delimiter_check(sub_string)
      delimiters.find do |delimiter|
        self.current_delimiter_match = match(sub_string, delimiter)
      end
    end

    def process_expressions(expressions)
      case expressions
      when Array
        expressions.hmap { |exp| [exp, exp] }
      when String, Symbol, Regexp
        { expressions => expressions }
      when Hash
        expressions
      else
        raise ArgumentError, "Unknown expression format: #{expressions.class}"
      end
    end
  end
end
