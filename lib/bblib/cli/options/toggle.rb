module BBLib
  class OptsParser
    class Toggle < Option

      def extract(index, args)
        value = args[index].to_s
        if value =~ /^\-[\w\d]$|^\-{2}/ || flags.include?(value)
          args[index] = nil
        elsif value =~ /^\-[\w\d]+$/
          flag = flags.find do |flag|
            next unless flag =~ /^\-[\w\d]$/
            value.include?(flag[1])
          end
          args[index] = value.sub(flag[1], '')
        end
        true
      end

      def to_s
        flags.sort_by(&:size).join(', ').strip.ljust(40, ' ') + "\t#{description}"
      end

      protected

      def simple_setup
        self.default = false
      end

    end
  end
end
