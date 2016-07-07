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
        data[:name] = data[:name].split(' |').first
        data[:osarchitecture] = data[:osarchitecture].extract_integers.first
        data.hpath_move( 'osarchitecture' => 'bits' )
        data[:host] = `hostname`.strip
        data[:os] = os
        data
      else
        release = {}
        begin
          release = `lsb_release -a`.split("\n").map do |l|
            spl = l.split(':')
            [
              spl.first.downcase.to_clean_sym,
              spl[1..-1].join(':').strip
            ]
          end.to_h
          release.hpath_move('description' => 'name', 'release' => 'name', 'distributor_id' => 'manufacturer')
        rescue
        end
        {
          release: `uname -r`,
          bits: `uname -r` =~ /x86_64/i ? 64 : 32,
          host: `uname -n`,
          os: os
        }.merge(release)
      end
    end

  end

end
