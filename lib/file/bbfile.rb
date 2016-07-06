

module BBLib

  # Takes one or more strings and normalizes slashes to create a consistent file path
  # Useful when concating two strings that when you don't know if one or both will end or begin with a slash
  def self.pathify *strings
    strings.map(&:to_s).msplit('/', '\\').map(&:strip).join('/')
  end

  # Scan for files and directories. Can be set to be recursive and can also have filters applied.
  def self.scan_dir path = Dir.pwd, filter: nil, recursive: false
    if !filter.nil?
      filter = [filter].flatten.map{ |f| path.to_s + (recursive ? '/**/' : '/') + f.to_s }
    else
      filter = (path.to_s + (recursive ? '/**/*' : '/*')).gsub('//', '/')
    end
    Dir.glob(filter)
  end

  # Uses BBLib.scan_dir but returns only files. Mode can be used to return strings (:path) or File objects (:file)
  def self.scan_files path, filter: nil, recursive: false, mode: :path
    BBLib.scan_dir(path, filter: filter, recursive: recursive).map{ |f| File.file?(f) ? (mode == :file ? File.new(f) : f) : nil}.reject{ |r| r.nil? }
  end

  # Uses BBLib.scan_dir but returns only directories. Mode can be used to return strings (:path) or Dir objects (:dir)
  def self.scan_dirs path, filter: nil, recursive: false, mode: :path
    BBLib.scan_dir(path, filter: filter, recursive: recursive).map{ |f| File.directory?(f) ? (mode == :dir ? Dir.new(f) : f ) : nil}.reject{ |r| r.nil? }
  end

  # Shorthand method to write a string to disk. By default the path is created if it doesn't exist.
  # Set mode to w to truncate file or leave at a to append.
  def self.string_to_file path, str, mkpath = true, mode: 'a'
    if !Dir.exists?(path) && mkpath
      FileUtils.mkpath File.dirname(path)
    end
    File.write(path, str.to_s, mode:mode)
  end

  # A file size parser for strings. Extracts any known patterns for file sizes.
  def self.parse_file_size str, output: :byte
    output = FILE_SIZES.keys.find{ |f| f == output || FILE_SIZES[f][:exp].include?(output.to_s.downcase) } || :byte
    bytes = 0.0
    FILE_SIZES.each do |k, v|
      v[:exp].each do |e|
        numbers = str.scan(/(?=\w|\D|\A)\d*\.?\d+[[:space:]]*#{e}s?(?=\W|\d|\z)/i)
        numbers.each{ |n| bytes+= n.to_f * v[:mult] }
      end
    end
    return bytes / FILE_SIZES[output][:mult]
  end

  # A mostly platform agnostic call to get root volumes
  def self.root_volumes
    if BBLib.windows?
      begin # For windows
        `wmic logicaldisk get name`.split("\n").map{ |m| m.strip }[1..-1].reject{ |r| r == '' }
      rescue
        begin # Windows attempt 2
          `fsutil fsinfo drives`.scan(/(?<=\s)\w\:/)
        rescue
          nil
        end
      end
    else
      begin
        `ls /`.split("\n").map{ |m| m.strip }.reject{ |r| r == '' }
      rescue # All attempts failed
        nil
      end
    end
  end

  # Windows only method to get the volume labels of disk drives
  def self.root_volume_labels
    return nil unless BBLib.windows?
    `wmic logicaldisk get caption,volumename`.split("\n")[1..-1].map{ |m| [m.split("  ").first.to_s.strip, m.split("  ")[1..-1].to_a.join(' ').strip] }.reject{ |o,t| o == '' }.to_h
  end

  FILE_SIZES = {
    byte:      { mult: 1, exp: ['b', 'byt', 'byte'] },
    kilobyte:  { mult: 1024, exp: ['kb', 'kilo', 'k', 'kbyte', 'kilobyte'] },
    megabyte:  { mult: 1048576, exp: ['mb', 'mega', 'm', 'mib', 'mbyte', 'megabyte'] },
    gigabyte:  { mult: 1073741824, exp: ['gb', 'giga', 'g', 'gbyte', 'gigabyte'] },
    terabyte:  { mult: 1099511627776, exp: ['tb', 'tera', 't', 'tbyte', 'terabyte'] },
    petabyte:  { mult: 1125899906842624, exp: ['pb', 'peta', 'p', 'pbyte', 'petabyte'] },
    exabyte:   { mult: 1152921504606846976, exp: ['eb', 'exa', 'e', 'ebyte', 'exabyte'] },
    zettabyte: { mult: 1180591620717411303424, exp: ['zb', 'zetta', 'z', 'zbyte', 'zettabyte'] },
    yottabyte: { mult: 1208925819614629174706176, exp: ['yb', 'yotta', 'y', 'ybyte', 'yottabyte'] }
  }

end

class File
  def dirname
    File.dirname(self.path)
  end
end

class String
  def to_file path, mkpath = true, mode: 'a'
    BBLib.string_to_file path, self, mkpath, mode:mode
  end

  def file_name with_extension = true
    self[(self.include?('/') ? self.rindex('/').to_i+1 : 0)..(with_extension ? -1 : self.rindex('.').to_i-1)]
  end

  def dirname
    self.scan(/.*(?=\/)/).first
  end

  def parse_file_size output: :byte
    BBLib.parse_file_size(self, output:output)
  end

  def pathify
    self.msplit('/', '\\').map(&:strip).join('/')
  end
end
