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

    def self.os_info
      if windows?
        data = `wmic os get manufacturer,name,organization,osarchitecture,version /format:list`
        data = data.split("\n").reject{ |r| r.strip == '' }.map do |m|
          spl = m.split('=')
          [spl.first.to_clean_sym.downcase, spl[1..-1].join('=')]
        end.to_h
        data[:name] = data[:name].split('|').first
        data[:osarchitecture] = data[:osarchitecture].extract_integers.first
        data.hpath_move( 'osarchitecture' => 'bits' )
        data[:host] = `hostname`.strip
        data[:os] = os
        data
      else
        release = {}
        begin
          # First attempt to get release info uses lsb_release
          release = `lsb_release -a`.split("\n").map do |l|
            spl = l.split(':')
            [
              spl.first.downcase.to_clean_sym,
              spl[1..-1].join(':').strip
            ]
          end.to_h
          release.hpath_move('description' => 'name', 'release' => 'name', 'distributor_id' => 'manufacturer')
        rescue
          # Try finding the release file and parsing it instead of lsb_release
          begin
            release = `cat /etc/*release`
              .split("\n")
              .reject{ |l| !(l.include?(':') || l.include?('=')) }
              .map{|l| l.msplit('=',':') }
              .map{ |a| [a.first.downcase.to_clean_sym, a[1..-1].join(':').uncapsulate] }
              .to_h
          rescue
            # Both attempts failed
          end
        end
        {
          release: `uname -r`.strip,
          bits: `uname -r` =~ /x86_64/i ? 64 : 32,
          host: `uname -n`.strip,
          os: os
        }.merge(release)
      end
    end

    # The following is Windows specific code
    if windows?

      def self.parse_wmic cmd
        `#{cmd} /format:list`
          .split("\n\n\n").reject(&:empty?)
          .map{ |l| l.split("\n\n")
            .map{ |l| spl = l.split('='); [spl.first.strip.downcase.to_clean_sym, spl[1..-1].join('=').strip ] }.to_h
          }.reject(&:empty?)
      end

    end

  end

end
