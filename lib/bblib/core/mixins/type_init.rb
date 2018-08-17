module BBLib
  # Requires Simple init to be loaded first. This sets up a very basic
  # init foundation by adding a method called type and setting the init
  # foundation method to it.
  module TypeInit

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:bridge_method, :type)
      base.send(:serialize_method, :type, always: true)
      base.send(:setup_init_foundation, :type) { |a, b| a && b && a.to_s.to_sym == b.to_s.to_sym }
    end

    module ClassMethods
      def type
        to_s.split('::').last.method_case.to_sym
      end
    end

  end
end
