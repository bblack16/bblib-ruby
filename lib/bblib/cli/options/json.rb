module BBLib
  class OptsParser
    class JSON < BasicOption

      protected

      def format_value(value)
        require 'json' unless defined?(::JSON)
        ::JSON.parse(value)
      rescue ::JSON::ParserError => e
        raise InvalidArgumentException, "Invalid JSON. #{e.to_s}"
      end

    end
  end
end
