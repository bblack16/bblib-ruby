
module BBLib
  module Prototype
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def prototype(opts = prototype_defaults)
        @prototype ||= self.new(*prototype_defaults)
      end

      def prototype_defaults
        []
      end

      def method_missing(method, *args, &block)
        prototype.respond_to?(method) ? prototype.send(method, *args, &block) : super
      end

      def respond_to_missing?(method, include_private = false)
        prototype.respond_to?(method) || super
      end
    end
  end
end
