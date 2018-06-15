module BBLib
  class OptsParser
    class String < BasicOption

      protected

      def format_value(value)
        value.to_s
      end

    end
  end
end
