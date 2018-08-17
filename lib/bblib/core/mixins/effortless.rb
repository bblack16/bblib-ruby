
module BBLib
  module Effortless
    def self.included(base)
      base.extend(BBLib::Attrs)
      base.extend(BBLib::Hooks)
      base.singleton_class.extend(BBLib::Hooks)
      base.extend(BBLib::FamilyTree)
      base.extend(BBLib::Bridge)
      base.send(:include, BBLib::Logger)
      base.send(:include, BBLib::Serializer)
      base.send(:include, BBLib::SimpleInit)
    end

    def _attrs
      self.class._attrs
    end
  end

  class EffortlessClass
    include Effortless
  end
end
