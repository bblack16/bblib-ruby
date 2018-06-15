module BBLib
  class OptsParser
    class Float < BasicOption

      protected

      def format_value(value)
        raise InvalidArgumentException, "Argument provided for #{name} should be an float but was '#{args[index]}'" unless value =~ /^\d+(\.\d+)?$/
        value.to_f
      end

    end
  end
end
