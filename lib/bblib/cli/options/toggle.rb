module BBLib
  class OptsParser
    class Toggle < Option

      def extract(index, args)
        value = args[index]
        if value =~ /^\-[\w\d]$/ || flags.include?(value)
          args.delete_at(index)
        elsif value =~ /^\-[\w\d]+$/
          flag = flags.find do |flag|
            next unless flag =~ /^\-[\w\d]$/
            value.include?(flag[1])
          end
          args[index] = value.sub(flag[1], '')
        end
        true
      end

      protected

      def simple_setup
        self.default = false
      end

    end
  end
end
