module BBLib
  class OptsParser
    class Untoggle < Option

      def extract(index, args)
        args.delete_at(index)
        false
      end

      protected

      def simple_setup
        self.default = true
      end

    end
  end
end
