module BBLib

  def self.in_opal?
    RUBY_ENGINE == 'opal'
  end

end

if BBLib.in_opal?
  class Element

    alias_native :replace_with, :replaceWith
    alias_native :prepend
    alias_native :get_context, :getContext
  end
end
