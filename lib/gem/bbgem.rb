
if defined? Gem

  module BBLib
    def self.gem_list
      Gem::Specification.map(&:name).uniq
    end

    def self.gem_installed?(name)
      BBLib.gem_list.include? name
    end
  end

  # Convenience method that will try to download and install a gem before requiring it
  # only if the gem is not already installed
  def require_gem(gem, name = nil)
    name = gem if name.nil?
    unless BBLib.gem_installed? name
      return false unless Gem.install gem
    end
    require name
  end

end
