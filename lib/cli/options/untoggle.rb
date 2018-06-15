module BBLib
  class OptsParser
    class Toggle < Option

      def extract(index, args)
        false
      end

    end
  end
end
