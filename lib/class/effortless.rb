require_relative 'simple_init'
require_relative 'attrs'
require_relative 'family_tree'
require_relative 'hooks'
require_relative 'serializer'

module BBLib
  module Effortless
    include SimpleInit

    class << self
      alias_method :_simple_init_included, :included
    end

    def self.included(base)
      _simple_init_included(base)
      base.extend(BBLib::Hooks)
      base.extend(BBLib::Attrs)
      base.extend(BBLib::FamilyTree)
    end
  end
end
