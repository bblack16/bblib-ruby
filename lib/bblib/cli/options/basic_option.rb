module BBLib
  class OptsParser
    class BasicOption < Option

      def extract(index, args)
        args[index] = nil
        raise MissingArgumentException, "No argument was provided for #{name}" if args[index + 1].nil?
        format_value(args[index + 1].tap { args[index + 1] = nil })
      end

      protected

      def format_value(value)
        raise AbstractError
      end

    end
  end
end
