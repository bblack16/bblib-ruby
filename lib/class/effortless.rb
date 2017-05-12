
module BBLib
  module Effortless
    def self.included(base)
      base.extend(BBLib::Attrs)
      base.extend(BBLib::Hooks)
      base.extend(BBLib::FamilyTree)
      base.send(:include, BBLib::Serializer)
      base.send(:include, BBLib::SimpleInit)
    end
  end

  class EffortlessClass
    include Effortless
  end
end
