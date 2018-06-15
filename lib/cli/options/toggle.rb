module BBLib
  class OptsParser
    class Toggle < Option

      def extract(index, args)
        true
      end

    end
  end
end
