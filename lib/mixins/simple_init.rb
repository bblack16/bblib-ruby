

module BBLib
  # Allows any public setter method to be called during initialization using keyword arguments.
  # Add include BBLib::SimpleInit or prepend BBLib::SimpleInit to classes to add this behavior.
  module SimpleInit
    attr_reader :_init_type

    INIT_TYPES = [:strict, :loose].freeze

    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        define_method(:initialize) do |*args, &block|
          send(:simple_setup) if respond_to?(:simple_setup, true)
          send(:simple_preinit, *args, &block) if respond_to?(:simple_preinit, true)
          _initialize(*args)
          send(:simple_init, *args, &block) if respond_to?(:simple_init, true)
          block.call(self) if block
        end
      end
    end

    module ClassMethods
      def init_type(type = nil)
        return @init_type ||= _super_init_type unless type
        raise ArgumentError, "Unknown init type '#{type}'. Must be #{INIT_TYPES.join_terms('or', encapsulate: "'")}." unless INIT_TYPES.include?(type)
        @init_type = type
      end

      def _super_init_type
        ancestors.each do |ancestor|
          next if ancestor == self
          return ancestor.init_type if ancestor.respond_to?(:init_type)
        end
        :strict
      end
    end

    protected


    def _initialize(*args)
      named = BBLib.named_args(*args)
      if self.class.respond_to?(:_attrs)
        missing = self.class._attrs.map do |method, details|
          next if send(method)
          details[:options][:required] && !named.include?(method) ? method : nil
        end.compact
        raise ArgumentError, "You are missing the following required #{BBLib.pluralize(missing.size, 'argument')}: #{missing.join_terms}" unless missing.empty?
      end
      named.each do |method, value|
        setter = "#{method}="
        exists = respond_to?(setter)
        raise ArgumentError, "Undefined attribute #{setter} for class #{self.class}." if !exists && self.class.init_type == :strict
        next unless exists
        send(setter, value)
      end
    end
  end
end
