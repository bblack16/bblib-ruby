
module BBLib
  
  class LazyClass
    
    def initialize *args, **named
      lazy_setup
      lazy_init(*args, **named)
    end
    
    protected
    
      def lazy_setup
        # Instantiate necessary variables here
      end
    
      def lazy_init *args, **named
        hash = named
        args.find_all{|a| a.is_a?(Hash)}.each{|a| hash.merge!(a)}
        hash.each do |k,v|
          if self.respond_to?("#{k}=".to_sym)
            send("#{k}=".to_sym, v)
          end
        end
        custom_lazy_init hash, *args
      end
      
      def custom_lazy_init hash, *args
        # Defined custom initialization here...
      end
    
  end
  
end