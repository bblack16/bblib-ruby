module BBLib

  def self.in_opal?
    RUBY_ENGINE == 'opal'
  end

end
