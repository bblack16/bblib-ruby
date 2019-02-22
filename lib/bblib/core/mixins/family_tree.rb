

module BBLib
  # Various methods for finding descendants and subclasses of a class. Intended as an
  # extend mixin for any class.
  module FamilyTree
    # Return all classes that inherit from this class
    def descendants(include_singletons = false)
      return _inherited_by.map { |c| [c, c.descendants] }.flatten.uniq if BBLib.in_opal?
      ObjectSpace.each_object(Class).select do |c|
        (include_singletons || !c.singleton_class?) && c < self
      end
    end

    alias subclasses descendants

    # Return all classes that directly inherit from this class
    def direct_descendants(include_singletons = false)
      return _inherited_by if BBLib.in_opal?
      ObjectSpace.each_object(Class).select do |c|
        (include_singletons || !c.singleton_class?) && c.ancestors[1..-1].find { |k| k.is_a?(Class) } == self
      end
    end

    # Return all live instances of the class
    # Passing false will not include instances of sub classes
    def instances(descendants = true)
      inst = ObjectSpace.each_object(self).to_a
      descendants ? inst : inst.select { |i| i.class == self }
    end

    def namespace
      BBLib.namespace_of(self)
    end

    def root_namespace
      BBLib.root_namespace_of(self)
    end

    alias direct_subclasses direct_descendants

    # If we are in Opal we need to track descendants a bit differently
    if BBLib.in_opal?
      def _inherited_by
        @_inherited_by ||= []
      end

      def inherited(klass)
        _inherited_by.push(klass)
      end
    end
  end
end
