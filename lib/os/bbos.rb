require_relative 'bbsys'


module BBLib

  module OS

    def self.os
      return :windows if windows?
      return :mac if mac?
      return :linux if linux?
    end

    def self.windows?
      builds = ['mingw', 'mswin', 'cygwin', 'bccwin']
      !(/#{builds.join('|')}/i =~ RUBY_PLATFORM).nil?
    end

    def self.linux?
      !windows? && !mac?
    end

    def self.unix?
      !windows?
    end

    def self.mac?
      builds = ['darwin']
      !(/#{builds.join('|')}/i =~ RUBY_PLATFORM).nil?
    end

  end

end
