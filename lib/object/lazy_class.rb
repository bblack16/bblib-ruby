
# frozen_string_literal: true
module BBLib
  class LazyClass
    extend Hooks
    extend Attr
    attr_reader :_serialize_fields

    def initialize(*args)
      self.class.hook_em_all
      _pre_setup
      lazy_setup
      _lazy_init(*args)
      yield self if block_given?
      _validate_required_params
    end

    def serialize
      _serialize_fields.map do |name, h|
        next if _dont_serialize_fields.include?(name)
        value = send(h[:method])
        if value.is_a?(Hash)
          value = value.map { |k, v| [k, v.respond_to?(:serialize) ? v.serialize : v] }.to_h
        elsif value.is_a?(Array)
          value = value.map { |v| v.respond_to?(:serialize) ? v.serialize : v }
        elsif value.respond_to?(:serialize)
          value = value.serialize
        end
        if !h[:always] && value == h[:ignore]
          nil
        else
          [name, value]
        end
      end.compact.to_h
    end

    def self.serialize_method(name, method = nil, ignore: nil, always: false)
      return if method == :serialize || name == :serialize && method.nil?
      _serialize_fields[name.to_sym] = {
        method: (method.nil? ? name.to_sym : method.to_sym),
        ignore: ignore,
        always: always
      }
    end

    def self.dont_serialize_method(*names)
      names.each { |name| _dont_serialize_fields.push(name) unless _dont_serialize_fields.include?(name) }
    end

    def self._serialize_fields
      @_serialize_fields ||= {}
    end

    def self._dont_serialize_fields
      @_dont_serialize_fields ||= []
    end

    def attrs
      self.class.attrs
    end

    # Return all classes that inherit from this class
    def self.descendants(include_singletons = false)
      ObjectSpace.each_object(Class).select do |c|
        (include_singletons || !c.singleton_class?) && c < self
      end
    end

    # Return all classes that directly inherit from this class
    def self.subclasses(include_singletons = false)
      ObjectSpace.each_object(Class).select do |c|
        (include_singletons || !c.singleton_class?) && c.ancestors[1] == self
      end
    end

    def self.instance_getters
      attrs.map { |k, v| [:attr_writer].any? { |t| v[:type] == t } ? nil : k }.compact
    end

    def self.instance_setters
      attrs.keys.map { |m| "#{m}=".to_sym }.select { |m| method_defined?(m) }
    end

    protected

    def lazy_setup
      # Instantiate necessary variables here
    end

    def _lazy_init(*args)
      self.class.ancestors.reverse.map { |a| a.instance_variable_get('@_serialize_fields') }.compact
          .each { |ary| ary.each { |k, v| v = v.dup; serialize_method(k, v.delete(:method), v) } }

      self.class.ancestors.reverse.map { |a| a.instance_variable_get('@_dont_serialize_fields') }.compact
          .each { |ary| ary.each { |k| dont_serialize_method(k) } }

      BBLib.named_args(*args).each do |k, v|
        send("#{k}=".to_sym, v) if respond_to?("#{k}=".to_sym)
      end

      lazy_init(*args)
      custom_lazy_init BBLib.named_args(*args), *args
    end

    def _pre_setup
      methods.each do |m|
        next unless m.to_s.start_with?('__reset_')
        begin
          send(m)
        rescue
          nil # Nothing to rescue, default initializer failed.
        end
      end

      # Fixes issues with duplication of defaults like arrays, hashes, etc...
      self.class.attrs.each do |k, v|
        begin
          default = v[:options][:default]
          if default.respond_to?(:clone) && !v[:options][:shared_default]
            send("#{k}=", v[:options][:default].clone)
          end
        rescue
        end
      end
    end

    def lazy_init(*args)
      # Define custom initialization here...
    end

    def custom_lazy_init(*args)
      # Left in for legacy support...don't use this!
    end

    def serialize_method(name, method = nil, ignore: nil, always: false)
      return if method == :serialize || name == :serialize && method.nil?
      _serialize_fields[name.to_sym] = {
        method: (method.nil? ? name.to_sym : method.to_sym),
        ignore: ignore,
        always: always
      }
    end

    def dont_serialize_method(*names)
      names.each { |name| _dont_serialize_fields.push(name) unless _dont_serialize_fields.include?(name) }
    end

    def _serialize_fields
      @_serialize_fields ||= {}
    end

    def _dont_serialize_fields
      @_dont_serialize_fields ||= []
    end

    def attr_serialize(hash, *klasses)
      if !klasses.any? { |c| hash.is_a?(c) }
        if hash.is_a?(Hash)
          klasses.first.new(hash)
        elsif hash.is_a?(Array)
          klasses.first.new(*hash)
        end
      else
        hash
      end
    end

    def _validate_required_params
      missing = []
      attrs.each do |method, hash|
        if hash[:options].include?(:required)
          if hash[:options][:required] && !hash[:options][:allow_nil] && send(method).nil?
            missing << method
          end
        end
      end
      raise ArgumentError, "You are missing the following parameter#{missing.size == 1 ? nil : 's'}: #{missing.join(', ')}" unless missing.empty?
    end
  end
end
