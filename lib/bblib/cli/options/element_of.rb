module BBLib
  class OptsParser
    class ElementOf < BasicOption

      attr_ary :options, aliases: :opts
      attr_of Proc, :comparitor, default: proc { |opt, val| opt == val }

      def valid?(value)
        return false unless options.any? { |opt| comparitor.call(opt, value) }
        return true if validators.empty?
        validators.all? do |validator|
          validator.call(value)
        end
      end

      protected

      def format_value(value)
        value.to_s
      end

    end
  end
end
