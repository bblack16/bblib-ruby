module BBLib
  # Easy way to see if all objects in an array are of a given class.
  def self.are_all?(klass, *objects)
    objects.all? { |object| object.is_a?(klass) }
  end

  # Easy way to see if any of the passed objects are of the given class.
  def self.are_any?(klass, *objects)
    objects.any? { |object| object.is_a?(klass) }
  end

  # Checks to see if an object is of any of the given classes.
  def self.is_any?(object, *klasses)
    klasses.any? { |klass| object.is_a?(klass) }
  end

  # Takes any type of object and converts it into a hash based on its instance
  # variables.
  def self.to_hash(obj)
    return { obj => nil } if obj.instance_variables.empty?
    hash = {}
    obj.instance_variables.each do |var|
      value = obj.instance_variable_get(var)
      if value.is_a?(Array)
        hash[var.to_s.delete('@')] = value.map { |v| v.respond_to?(:obj_to_hash) && !v.instance_variables.empty? ? v.obj_to_hash : v }
      elsif value.is_a?(Hash)
        begin
          unless hash[var.to_s.delete('@')].is_a?(Hash) then hash[var.to_s.delete('@')] = {} end
        rescue
          hash[var.to_s.delete('@')] = {}
        end
        value.each do |k, v|
          hash[var.to_s.delete('@')][k.to_s.delete('@')] = v.respond_to?(:obj_to_hash) && !v.instance_variables.empty? ? v.obj_to_hash : v
        end
      elsif value.respond_to?(:obj_to_hash) && !value.instance_variables.empty?
        hash[var.to_s.delete('@')] = value.obj_to_hash
      else
        hash[var.to_s.delete('@')] = value
      end
    end
    hash
  end

  # Extracts all hash based arguments from an ary of arguments. Only hash pairs with
  # a symbol as the key are returned. Use hash_args if you also want to treat
  # String keys as named arguments.
  def self.named_args(*args)
    args.last.is_a?(Hash) && args.last.keys.all? { |k| k.is_a?(Symbol) } ? args.last : {}
  end

  # Same as standard named_args but removes the named arguments from the array.
  def self.named_args!(*args)
    if args.last.is_a?(Hash) && args.last.keys.all? { |k| k.is_a?(Symbol) }
      args.delete_at(-1)
    else
      {}
    end
  end

  # Similar to named_args but also treats String keys as named arguments.
  def self.hash_args(*args)
    args.find_all { |a| a.is_a?(Hash) }.each_with_object({}) { |a, h| h.merge!(a) }
  end

  # Send a chain of methods to an object and each result of the previous method.
  def self.recursive_send(obj, *methods)
    methods.each do |args|
      obj = obj.send(*args)
    end
    obj
  end

  # Returns the encapsulating object space of a given class.
  # Ex: For a class called BBLib::String, this method will return BBLib as the namespace.
  # Ex2: For a class BBLib::String::Char, this method will return BBLib::String as the namespace.
  def self.namespace_of(klass)
    split = klass.to_s.split('::')
    return klass if split.size == 1
    Object.const_get(split[0..-2].join('::'))
  end

  # Returns the root namespace of a given class if it is nested.
  def self.root_namespace_of(klass)
    Object.const_get(klass.to_s.gsub(/::.*/, ''))
  end

  # Create a new class or module recursively within a provided namespace. If a
  # constant matching the requested one already exist it is returned. Any
  # block passed to this method will be evaled in the created/found constant.
  def self.const_create(name, value, strict: true, base: Object, type_of_missing: nil, &block)
    namespace = base
    unless base.const_defined?(name)
      type_of_missing = Module unless type_of_missing
      name = name.uncapsulate('::')
      if name.include?('::')
        namespaces = name.split('::')
        name = namespaces.pop
        namespaces.each do |constant|
          unless namespace.const_defined?(constant)
            match = namespace.const_set(constant, type_of_missing.new)
          end
          namespace = namespace.const_get(constant)
        end
      end
      namespace.const_set(name, value)
    end
    object = namespace.const_get(name)
    raise TypeError, "Expected a #{value.class} but #{namespace}::#{name} is a #{object.class}" if strict && object.class != value.class
    object.tap do |constant|
      constant.send(:class_exec, &block) if block
    end
  end

  def self.class_create(name, *args, **opts, &block)
    const_create(name, Class.new(*args), **opts, &block)
  end

  def self.module_create(name, *args, **opts, &block)
    const_create(name, Module.new(*args), **opts, &block)
  end
end
