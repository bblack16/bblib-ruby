

module BBLib

  module Serializer
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def _serialize_fields
        @_serialize_fields ||= _ancestor_serialize_fields
      end

      def _ancestor_serialize_fields
        hash = {}
        ancestors.reverse.map do |ancestor|
          next unless ancestor.respond_to?(:_serialize_fields) && ancestor != self
          hash = hash.deep_merge(ancestor._serialize_fields)
        end
        hash
      end

      def _dont_serialize_fields
        @_dont_serialize_fields ||= _ancestor_dont_serialize_fields
      end

      def _ancestor_dont_serialize_fields
        ancestors.reverse.flat_map do |ancestor|
          next unless ancestor.respond_to?(:_dont_serialize_fields) && ancestor != self
          ancestor._dont_serialize_fields
        end.compact.uniq
      end

      def dont_serialize_method(method)
        _dont_serialize_fields.push(method) unless _dont_serialize_fields.include?(method)
      end

      def serialize_method(name, method = nil, **opts)
        return false if method == :serialize || name == :serialize && method.nil?
        _serialize_fields[name.to_sym] = {
          method: (method || name).to_sym
        }.merge(opts)
      end
    end

    def serialize(ignore_defaults = false)
      self.class._serialize_fields.map do |name, opts|
        next if self.class._dont_serialize_fields.include?(name)
        args = [opts[:method]] + (opts.include?(:args) ? [opts[:args]].flatten(1) : [])
        value = send(*args)
        next if value == self
        unless opts[:flat]
          if value.is_a?(Hash)
            value = value.map { |k, v| [k, v != self && v.respond_to?(:serialize) ? v.serialize(ignore_defaults) : v] }.to_h
          elsif value.is_a?(Array)
            value = value.map { |v| v != self && v.respond_to?(:serialize) ? v.serialize(ignore_defaults) : v }
          elsif value.respond_to?(:serialize)
            value = value.serialize(ignore_defaults)
          end
        end
        if !opts[:always] && (ignore_defaults && value == opts[:default] || opts.include?(:ignore) && value == opts[:ignore])
          nil
        else
          [name, value]
        end
      end.compact.to_h
    end
  end

end
