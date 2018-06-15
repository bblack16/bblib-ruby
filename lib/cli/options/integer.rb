module BBLib
  class OptsParser
    class Integer < BasicOption

      protected

      def format_value(value)
        raise InvalidArgumentException, "Argument provided for #{name} should be an integer but was '#{args[index]}'" unless value =~ /^\d+$/
        value.to_i
      end

    end
  end
end
