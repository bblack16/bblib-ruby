module BBLib
  class OptsParser
    class Option
      include BBLib::Effortless
      include BBLib::TypeInit

      attr_sym :name, default_proc: :determine_name
      attr_str :description, aliases: :desc
      attr_of Object, :default, allow_nil: true, default: nil
      attr_str :placeholder, default_proc: proc { |x| x.name.upcase }
      attr_ary_of String, :flags
      attr_of [String, Regexp], :delimiter, default: nil, allow_nil: true
      attr_str :argument_delimiter, default: ' '
      attr_bool :raise_errors, default: true
      attr_bool :required, default: false
      attr_of Proc, :processor, arg_at: :block, default: nil, allow_nil: true
      attr_ary_of Proc, :validators
      attr_bool :singular, default: true
      attr_of [Integer, Range], :position, default: nil, allow_nil: true
      attr_hash :sub_commands, keys: String, values: OptsParser, aliases: [:sub_cmds, :subcommands], default: nil, allow_nil: true, pre_proc: proc { |hash| hash.is_a?(Hash) ? hash.keys_to_s : hash }

      def to_s
        (flags.sort_by(&:size).join(', ') + " #{placeholder}").strip.ljust(40, ' ') + "\t#{description}"
      end

      def self.types
        descendants.flat_map(&:type)
      end

      def retrieve(args, parsed)
        result = multi_value? ? [] : nil
        index = 0
        until index >= args.size
          begin
            if args[index].nil? || !flag_match?(args[index].to_s, index)
              index += 1
              next
            end
            values = split(extract(index, args))
            values.each do |value|
              valid!(value)
              if multi_value?
                result << value
              else
                result = value
              end
              index = args.size if singular?
            end
          rescue OptsParserException => e
            raise e if raise_errors?
          end
          index += 1
        end
        raise MissingArgumentException, "A required argument is missing: #{name}" if required? && result.nil?
        result = processor.call(result) if !result.nil? && processor
        process_result(result.nil? ? default : result, args, parsed)
      end

      def multi_value?
        !singular || delimiter
      end

      def flag_match?(str, index = 0)
        text_match = if flags.empty? && position
          true
        elsif argument_delimiter == ' '
          if !str.include?(' ') && str =~ /^\-[^\-]/
            flags.any? do |flag|
              flag =~ /^\-[\w\d]/ && str.include?(flag[1])
            end
          else
            flags.include?(str)
          end
        else
          flags.any? do |flag|
            flag.start_with?("#{str}#{argument_delimiter}")
          end
        end
        return text_match unless text_match && position
        position === index
      end

      def valid?(value)
        return true if validators.empty?
        validators.all? do |validator|
          validator.call(value)
        end
      end

      def valid!(value)
        raise InvalidArgumentException, "Invalid argument for #{name}" unless valid?(value)
      end

      def split(value)
        return [value] unless delimiter
        value.msplit(delimiter)
      end

      protected

      def determine_name
        flag = flags.find { |f| f.start_with?('--') }
        flag = flags.first unless flag
        flag.to_s.sub(/^-{1,2}/, '').snake_case
      end

      def process_result(result, args, parsed)
        parsed.deep_merge!(name => result)
        if sub_commands && sub_commands[result]
          parsed.deep_merge!(sub_commands[result].parse!(args))
        end
      end

    end
  end
end
