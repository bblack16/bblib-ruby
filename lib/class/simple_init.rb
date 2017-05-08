

module BBLib
  # Allows any public setter method to be called during initialization using keyword arguments.
  # Add include BBLib::SimpleInit or prepend BBLib::SimpleInit to classes to add this behavior.
  module SimpleInit
    attr_reader :_init_type

    INIT_TYPES = [:strict, :loose].freeze

    def self.included(base)
      base.class_eval do
        original_method = instance_method(:initialize) if base.private_instance_methods.include?(:initialize)
        define_method(:initialize) do |*args, &block|
          send(:simple_setup) if respond_to?(:simple_setup)
          original_method.bind(self).call(*args, &block) if original_method
          _initialize(*args)
          send(:simple_init, *args) if respond_to?(:simple_init)
          yield self if block_given?
        end
      end
    end

    protected

    def _init_type=(type)
      raise ArgumentError, "Unknown init type '#{type}'. Must be #{INIT_TYPES.join_terms('or', encapsulate: "'")}." unless INIT_TYPES.include?(type)
      @_init_type = type
    end

    def _initialize(*args)
      named = BBLib.named_args(*args)
      self._init_type = named[:init_type] || named[:_init_type] || :strict
      named.each do |method, value|
        setter = "#{method}="
        exists = respond_to?(setter)
        raise ArgumentError, "Undefined setter #{setter} for class #{self.class}." if !exists && _init_type == :strict
        next unless exists
        send(setter, value)
      end
    end
  end
end
