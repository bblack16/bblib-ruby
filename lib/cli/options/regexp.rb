module BBLib
  class OptsParser
    class Regexp < BasicOption

      protected

      def format_value(value)
        if value =~ /^\/.*\/\w*$/
          value.to_regex
        else
          /#{value}/
        end
      end

    end
  end
end
