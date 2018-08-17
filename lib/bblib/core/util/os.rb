module BBLib
  module OS
    def self.os
      return :windows if windows?
      return :mac if mac?
      return :linux if linux?
    end

    def self.windows?
      builds = %w(mingw mswin cygwin bccwin)
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

    # Mostly platform agnost way to find the full path of an executable in the current env path.
    def self.which(cmd)
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        (ENV['PATHEXT']&.split(';') || ['']).each do |ext|
          executable = File.join(path, "#{cmd}#{ext.downcase}").pathify
          return executable if File.executable?(executable) && !File.directory?(executable)
        end
      end
      nil
    end
  end
end
