# Similar to Ruby's OpenStruct but uses hash as its parent class providing
# all of the typical Hash methods. Useful for storing settings on objects.
module BBLib
  class HashStruct < Hash

    protected

    def method_missing(method, *args, &block)
      if args.empty? && ![:to_ary].include?(method)
        if method.to_s.end_with?('?')
          define_singleton_method(method) do
            self[method[0..-2].to_sym] ? true : false
          end
          send(method)
        else
          define_singleton_method(method) do
            self[method]
          end
          self[method]
        end
      elsif method.to_s.end_with?('=')
        define_singleton_method(method) do |arg|
          self[method[0..-2].to_sym] = arg
        end
        self[method[0..-2].to_sym] = args.first
      else
        super
      end
    end
  end
end
