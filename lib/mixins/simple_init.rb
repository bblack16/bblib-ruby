

module BBLib
  # Allows any public setter method to be called during initialization using keyword arguments.
  # Add include BBLib::SimpleInit or prepend BBLib::SimpleInit to classes to add this behavior.
  module SimpleInit
    attr_reader :_init_type

    # strict - Raise exceptions for unknown named attributes
    # loose - Ignore unknown named attributes
    # collect - Put unknown named attributes into the attribute
    #           configured by collect_attribute
    INIT_TYPES = [:strict, :loose, :collect].freeze

    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        define_method(:initialize) do |*args, &block|
          send(:simple_setup) if respond_to?(:simple_setup, true)
          send(:simple_preinit, *args, &block) if respond_to?(:simple_preinit, true)
          _initialize(*args, &block)
          send(:simple_init, *args, &block) if respond_to?(:simple_init, true)
          if block && !_attrs.any? { |k, v| v[:options][:arg_at] == :block }
            result = instance_eval(&block)
            simple_init_block_result(result) if respond_to?(:simple_init_block_result, true)
          end
        end
      end

      if BBLib.in_opal?
        base.singleton_class.class_eval do
          alias __new new

          def new(*args, &block)
            named = BBLib.named_args(*args)
            if init_foundation && named[init_foundation_method] && ((named[init_foundation_method] != self.send(init_foundation_method)) rescue false)
              klass = [self, descendants].flatten.find do |k|
                if init_foundation_compare
                  init_foundation_compare.call(k.send(init_foundation_method), named[init_foundation_method])
                else
                  k.send(init_foundation_method).to_s == named[init_foundation_method].to_s
                end
              end
              raise ArgumentError, "Unknown #{init_foundation_method} \"#{named[init_foundation_method]}\" for #{self}" unless klass
              klass == self ? __new(*args, &block) : klass.new(*args, &block)
            elsif named[init_foundation_method].nil? && init_foundation_default_class != self
              init_foundation_default_class.new(*args, &block)
            else
              __new(*args, &block)
            end
          end
        end
      end
    end

    module ClassMethods

      unless BBLib.in_opal?
        # Overriden new method that allows parent classes to dynamically generate
        # instantiations of descendants by using the named init_foundation_method argument.
        def new(*args, &block)
          named = BBLib.named_args(*args)
          if init_foundation && named[init_foundation_method] && ((named[init_foundation_method] != self.send(init_foundation_method)) rescue false)
            klass = [self, descendants].flatten.find do |k|
              if init_foundation_compare
                init_foundation_compare.call(k.send(init_foundation_method), named[init_foundation_method])
              else
                k.send(init_foundation_method).to_s == named[init_foundation_method].to_s
              end
            end
            raise ArgumentError, "Unknown #{init_foundation_method} \"#{named[init_foundation_method]}\"" unless klass
            klass == self ? super : klass.new(*args, &block)
          elsif named[init_foundation_method].nil? && init_foundation_default_class != self
            init_foundation_default_class.new(*args, &block)
          else
            super
          end
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
        @init_foundation_compare = block if block
        @init_foundation_compare
      end

      def setup_init_foundation(method, &block)
        self.init_foundation = true
        self.init_foundation_method(method)
        self.init_foundation_compare(&block) if block
      end

      def init_foundation_default_class
        self
      end

      def collect_method(name = nil)
        @collect_method = name if name
        @collect_method ||= _super_collect_method
      end

      def _super_collect_method
          ancestors.each do |ancestor|
            next if ancestor == self
            return ancestor.collect_method if ancestor.respond_to?(:collect_method)
          end
          :attributes
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

    def _initialize(*args, &block)
      named = BBLib.named_args(*args)
      if self.class.respond_to?(:_attrs)
        set_v_arg = self.class._attrs.map do |method, details|
          next unless details[:options][:arg_at] && (details[:options][:arg_at].is_a?(Integer) || details[:options][:arg_at] == :block)
          if details[:options][:arg_at] == :block
            send("#{method}=", block) if block
            method
          else
          index = details[:options][:arg_at]
            if args.size > index
              accept = details[:options][:arg_at_accept]
              next if args[index].is_a?(Hash) && (accept.nil? || ![accept].flatten.include?(Hash))
              if accept.nil? || [accept].flatten.any? { |a| a >= args[index].class }
                send("#{method}=", args[index])
                method
              end
            end
          end
        end.compact
        missing = self.class._attrs.map do |method, details|
          next unless !set_v_arg.include?(method) && details[:options][:required] && !named.include?(method) && !send(method)
          method
        end.compact
        raise ArgumentError, "You are missing the following required #{BBLib.pluralize('argument', missing.size)} for #{self.class}: #{missing.join_terms}" unless missing.empty?
      end
      named.each do |method, value|
        next if method == self.class.init_foundation_method
        setter = "#{method}="
        exists = respond_to?(setter)
        if !exists && self.class.init_type == :strict
          raise ArgumentError, "Undefined attribute #{setter} for class #{self.class}."
        elsif !exists && self.class.init_type == :collect
          _collect_attribute(method, value)
        end
        next unless exists
        send(setter, value)
      end
    end

    def _collect_attribute(method, value)
      inst_name = "@#{self.class.collect_method}"
      hash = instance_variable_get(inst_name)
      hash = instance_variable_set(inst_name, {}) unless hash.is_a?(Hash)
      hash[method] = value
    end
  end
end
