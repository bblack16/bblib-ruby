module BBLib

  def self.in_opal?
    RUBY_ENGINE == 'opal'
  end

end

if BBLib.in_opal?
  class Element

    alias_native :replace_with, :replaceWith
    alias_native :prepend
    
  end
end
