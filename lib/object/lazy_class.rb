
module BBLib

  class LazyClass
    extend Hooks
    extend Attr
    attr_reader :_serialize_fields

    def initialize *args
      _pre_setup
      lazy_setup
      _lazy_init(*args)
    end

    def serialize
      _serialize_fields.map do |name, h|
        value = send(h[:method])
        if value.is_a?(Hash)
          value = value.map{ |k, v| [k, v.respond_to?(:serialize) ? v.serialize : v] }.to_h
        elsif value.is_a?(Array)
          value = value.map{ |v| v.respond_to?(:serialize) ? v.serialize : v }
        elsif value.respond_to?(:serialize)
          value = value.serialize
        end
        if !h[:always] && value == h[:ignore]
          nil
        else
          [ name, value ]
        end
      end.compact.to_h
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

        self.class.ancestors.reverse.map{ |a| a.instance_variable_get('@_serialize_fields') }.compact
              .each{ |ary| ary.each{ |k, v| self.serialize_method(k, v.delete(:method), v) } }
      end

      def _pre_setup
        self.methods.each do |m|
          if m.to_s.start_with?('__reset_')
            send(m) rescue nil
          end
        end
      end

      def lazy_init *args
        # Define custom initialization here...
      end

      def custom_lazy_init *args
        # Left in for legacy support...don't use this!
      end

      def serialize_method name, method = nil, ignore: nil, always: false
        return if method == :serialize || name == :serialize && method.nil?
        _serialize_fields[name.to_sym] = {
          method: (method.nil? ? name.to_sym : method.to_sym),
          ignore: ignore,
          always: always
        }
      end

      def self.serialize_method name, method = nil, ignore: nil, always: false
        return if method == :serialize || name == :serialize && method.nil?
        _serialize_fields[name.to_sym] = {
          method: (method.nil? ? name.to_sym : method.to_sym),
          ignore: ignore,
          always: always
        }
      end

      def _serialize_fields
        @_serialize_fields ||= Hash.new
      end

      def self._serialize_fields
        @_serialize_fields ||= Hash.new
      end

      def attr_serialize klass, hash
        if !hash.is_a?(klass) && hash.is_a?(Hash)
          klass.new(hash)
        else
          hash
        end
      end

  end

end
