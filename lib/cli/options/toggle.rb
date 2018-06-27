module BBLib
  class OptsParser
    class Toggle < Option

      def extract(index, args)
        args.delete_at(index)
        true
      end

      protected

      def simple_setup
        self.default = false
      end

    end
  end
end
