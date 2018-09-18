module BBLib
  class OptsParser
    class Command < Option
      attr_of [Integer, Range], :position, default: nil, allow_nil: true, arg_at: 0

      def self.type
        [super, :at]
      end

      def extract(index, args)
        args.delete_at(index).to_s
      end

    end
  end
end
