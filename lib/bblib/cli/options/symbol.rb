module BBLib
  class OptsParser
    class Symbol < BasicOption

      protected

      def format_value(value)
        value.to_sym
      end

    end
  end
end
