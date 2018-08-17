module BBLib
  class OptsParser
    class Date < BasicOption

      protected

      # TODO Support custom formats
      def format_value(value)
        ::Date.parse(value)
      end

    end
  end
end
