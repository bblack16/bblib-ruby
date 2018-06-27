module BBLib
  class OptsParser
    class BasicOption < Option

      def extract(index, args)
        args.delete_at(index)
        raise MissingArgumentException, "No argument was provided for #{name}" if args[index].nil?
        format_value(args.delete_at(index))
      end

      protected

      def format_value(value)
        raise AbstractError
      end

    end
  end
end
