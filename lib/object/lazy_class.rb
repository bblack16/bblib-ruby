
module BBLib

  class LazyClass
    extend Hooks
    extend Attr

    def initialize *args
      lazy_setup
      lazy_init(*args)
    end

    protected

      def lazy_setup
        # Instantiate necessary variables here
      end

      def _lazy_init *args
        BBLib::named_args(*args).each do |k,v|
          if self.respond_to?("#{k}=".to_sym)
            send("#{k}=".to_sym, v)
          end
        end
        lazy_init *args
        custom_lazy_init BBLib::named_args(*args), *args
      end

      def lazy_init *args
        # Define custom initialization here...
      end

      def custom_lazy_init *args
        # Left in for legacy support...don't use this!
      end

  end

end
