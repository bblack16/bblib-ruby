module BBLib
  class OptsParser
    class Time < BasicOption

      protected

      # TODO Support custom formats
      def format_value(value)
        ::Time.parse(value)
      end

    end
  end
end
