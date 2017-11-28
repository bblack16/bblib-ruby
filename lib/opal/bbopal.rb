module BBLib
  def self.in_opal?
    RUBY_ENGINE == 'opal'
  end

  # Used when a method is called while in the wrong engine (such as Opal)
  class WrongEngineError < StandardError; end
end

if BBLib.in_opal?
  class Element
    alias_native :replace_with, :replaceWith
    alias_native :prepend
    alias_native :insert_after, :insertAfter
    alias_native :insert_before, :insertBefore
  end
end
