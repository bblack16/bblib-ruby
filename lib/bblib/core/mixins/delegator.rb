
module BBLib
  module Delegator
    def self.included(base)
      base.extend(ClassMethods)
      base.send(:attr_ary, :instance_delegates)
    end

    def delegates
      (instance_delegates + self.class.delegates).uniq
    end

    protected

    def method_missing(method, *args, &block)
      delegates.each do |delegate|
        case delegate
        when Symbol
          next unless respond_to?(delegate) && method(delegate).arity == 0
          object = send(delegate)
          next unless object.respond_to?(method)
          return object.send(method, *args, &block)
        else
          next unless delegate.respond_to?(method)
          return delegate.send(method, *args, &block)
        end
      end
      super
    end

    def respond_to_missing?(method, include_private = false)
      return super if self.class.delegate_fast
      super || delegates.any? do |delegate|
        next if delegate == self # Protection from recursion
        case delegate
        when Symbol
          self.method(delegate)&.arity == 0 &&
          send(delegate).respond_to?(method)
        else
          delegate.respond_to?(method)
        end
      end
    end

    def delegate_to(*mthds)
      mthds.flatten.each do |method|
        next if instance_delegates.include?(method)
        instance_delegates << method
      end
      true
    end

    module ClassMethods
      # When turned on the respond_to_missing method is left unchanged.
      # This GREATLY speeds up the instantiation of classes with lots of
      # calls to respond_to?
      def delegate_fast(*args)
        return @delegate_fast ||= _ancestor_delegate_fast if args.empty?
        @delegate_fast = args.first ? true : false
      end

      def delegate_to(*mthds)
        mthds.flatten.each do |method|
          next if delegates.include?(method)
          delegates << method
        end
        true
      end

      def _ancestor_delegate_fast
        ancestors.reverse.find do |anc|
          next if anc == self
          next unless anc.respond_to?(:delegate_fast)
          return anc.delegate_fast
        end
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
