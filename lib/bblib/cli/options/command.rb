module BBLib
  class OptsParser
    class Command < Option
      attr_of [Integer, Range], :position, default: nil, allow_nil: true, arg_at: 0

      def self.type
        [super, :at]
      end

      def extract(index, args)
        args[index].tap { args[index] = nil }
      end

    end
  end
end
