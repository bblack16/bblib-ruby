module BBLib
  class OptsParser
    class Command < Option

      def extract(index, args)
        args.delete_at(index)
      end

    end
  end
end
