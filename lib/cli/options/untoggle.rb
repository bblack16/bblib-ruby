module BBLib
  class OptsParser
    class Untoggle < Toggle

      def extract(index, args)
        super
        false
      end

      protected

      def simple_setup
        self.default = true
      end

    end
  end
end
