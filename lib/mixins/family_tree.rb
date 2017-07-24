

module BBLib
  # Various methods for finding descendants and subclasses of a class. Intended as an
  # extend mixin for any class.
  module FamilyTree
    # Return all classes that inherit from this class
    def descendants(include_singletons = false)
      ObjectSpace.each_object(Class).select do |c|
        (include_singletons || !c.singleton_class?) && c < self
      end
    end

    alias subclasses descendants

    # Return all classes that directly inherit from this class
    def direct_descendants(include_singletons = false)
      ObjectSpace.each_object(Class).select do |c|
        (include_singletons || !c.singleton_class?) && c.ancestors[1] == self
      end
    end

    alias direct_subclasses direct_descendants

  end
end