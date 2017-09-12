

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
      # Overriden new method that allows parent classes to dynamically generate
      # instantiations of descendants by using the named :_class argument.
      # :_class needs to be the fully qualified name of the descendant.
      def new(*args, &block)
        named = BBLib.named_args(*args)
        if init_foundation && named[init_foundation_method] && ((named[init_foundation_method] != self.send(init_foundation_method)) rescue false)
          klass = descendants.find do |k|
            if init_foundation_compare
              init_foundation_compare.call(k.send(init_foundation_method), named[init_foundation_method])
            else
              k.send(init_foundation_method).to_s == named[init_foundation_method].to_s
            end
          end
          raise ArgumentError, "Unknown class type #{named[init_foundation_method]}" unless klass
          klass.new(*args, &block)
        else
          super
        end
      end

      # If true, this allows the overriden new method to generate descendants from
      # its constructors.
      def init_foundation
        @init_foundation ||= false
      end

      # Sets the init_foundation variable to true of false. When false, the new
      # method behaves like any other class. If true, the new method can instantiate
      # child classes using the :_class named parameter.
      def init_foundation=(toggle)
        @init_foundation = toggle
      end

      def init_foundation_method(method = nil)
        @init_foundation_method = method if method
        @init_foundation_method ||= ancestor_init_foundation_method
      end

      def init_foundation_compare(&block)
        @init_foundation_compare = block if block_given?
        @init_foundation_compare
      end

      def setup_init_foundation(method, &block)
        self.init_foundation = true
        self.init_foundation_method(method)
        self.init_foundation_compare(&block) if block_given?
      end

      def ancestor_init_foundation_method
        anc = ancestors.find do |a|
          next if a == self
          a.respond_to?(:init_foundation_method)
        end
        anc ? anc.init_foundation_method : :_class
      end

      # Sets or returns the current init type for this class.
      # Available types are:
      #=> :strict = Unknown named arguments will raise an error.
      #=> :loose  = Unknown named arguments are ignored.
      def init_type(type = nil)
        return @init_type ||= _super_init_type unless type
        raise ArgumentError, "Unknown init type '#{type}'. Must be #{INIT_TYPES.join_terms('or', encapsulate: "'")}." unless INIT_TYPES.include?(type)
        @init_type = type
      end

      # Used to load the init type of the nearest ancestor for inheritance.
      def _super_init_type
        ancestors.each do |ancestor|
          next if ancestor == self
          return ancestor.init_type if ancestor.respond_to?(:init_type)
        end
        :strict
      end

      # Dynamically create a new class based on this one. By default this class
      # is generated in the same namespace as the parent class. A custom namespace
      # can be passed in using the named argument :namespace.
      def build_descendant(name, namespace: parent_namespace)
        namespace.const_set(name, Class.new(self))
      end

      # Returns the nearest parent namespace to thi current class. Object is
      # returned if this class is not in a namespace.
      def parent_namespace
        parent = self.to_s.split('::')[0..-2].join('::')
        if parent.empty?
          return Object
        else
          Object.const_get(parent)
        end
      end

      def _class
        self.to_s
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
        raise ArgumentError, "You are missing the following required #{BBLib.pluralize('argument', missing.size)}: #{missing.join_terms}" unless missing.empty?
      end
      named.each do |method, value|
        next if method == self.class.init_foundation_method
        setter = "#{method}="
        exists = respond_to?(setter)
        raise ArgumentError, "Undefined attribute #{setter} for class #{self.class}." if !exists && self.class.init_type == :strict
        next unless exists
        send(setter, value)
      end
    end
  end
end
