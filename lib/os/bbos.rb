require_relative 'bbsys'


module BBLib

  def self.os
    return :windows if BBLib.windows?
    return :mac if BBLib.mac?
    return :linux if BBLib.linux?
  end

  def self.windows?
    builds = ['mingw', 'mswin', 'cygwin', 'bccwin']
    !(/#{builds.join('|')}/i =~ RUBY_PLATFORM).nil?
  end

  def self.linux?
    !BBLib.windows? && !BBLib.mac?
  end

  def self.unix?
    !BBLib.windows?
  end

  def self.mac?
    builds = ['darwin']
    !(/#{builds.join('|')}/i =~ RUBY_PLATFORM).nil?
  end


end
