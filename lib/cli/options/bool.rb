module BBLib
  class OptsParser
    class Bool < BasicOption

      TRUE_STATEMENTS = %w{true yes y t 1}
      FALSE_STATEMENTS = %w{false no n f 0}

      protected

      def format_value(value)
        tru = TRUE_STATEMENTS.any? { |ts| ts == value.downcase }
        fal = FALSE_STATEMENTS.any? { |fs| fs == value.downcase }
        raise InvalidArgumentException, "#{name} is a boolean argument but got a non-boolean value" unless tru || fal
        tru && !fal
      end

    end
  end
end
