
module BBLib
  module Delegator
    def self.included(base)
      base.extend(ClassMethods)
    end

    protected

    def method_missing(method, *args, &block)
      self.class.delegates.each do |delegate|
        next unless respond_to?(delegate) && method(delegate).arity == 0
        object = send(delegate)
        next unless object.respond_to?(method)
        return object.send(method, *args, &block)
      end
      super
    end

    def respond_to_missing?(method, include_private = false)
      self.class.delegates.any? do |delegate|
        self.method(delegate)&.arity == 0 &&
        send(delegate).respond_to?(method)
      end || super
    end

    module ClassMethods
      def delegate_to(*mthds)
        mthds.flatten.each { |method| delegates << method.to_sym }
        true
      end

      def delegates
        @delegates ||= ancestor_delegates
      end

      def ancestor_delegates
        ancestors.reverse.flat_map do |anc|
          next if anc == self || !anc.respond_to?(:delegates)
          anc.delegates
        end.compact.uniq
      end
    end
  end
end
