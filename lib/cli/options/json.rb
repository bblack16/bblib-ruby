module BBLib
  class OptsParser
    class JSON < BasicOption

      protected

      def format_value(value)
        require 'json' unless defined?(::JSON)
        ::JSON.parse(value)
      end

    end
  end
end
