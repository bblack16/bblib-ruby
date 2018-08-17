
module BBLib
  # Adds basic convenience methods to a class to extend getters or setters from
  # class methods to instances.
  module Bridge

    def bridge_method(*class_methods)
      class_methods.each do |class_method|
        define_method(class_method) do |*args|
          self.class.send(class_method, *args)
        end
      end
      true
    end

  end
end
