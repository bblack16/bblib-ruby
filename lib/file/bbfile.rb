

module BBLib

  # Scan for files and directories. Can be set to be recursive and can also have filters applied.
  def self.scan_dir path = Dir.pwd, filter: nil, recursive: false
    if !filter.nil?
      filter = [filter].flatten.map{ |f| path.to_s + (recursive ? '/**/' : '/') + f.to_s }
    else
      filter = path.to_s + (recursive ? '/**/*' : '/*')
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

  # Shorthand method to write a string to dist. By default the path is created if it doesn't exist.
  def self.string_to_file path, str, mkpath = true
    if !Dir.exists?(path) && mkpath
      FileUtils.mkpath File.dirname(path)
    end
    File.write(path, str.to_s)
  end

  # A file size parser for strings. Extracts any known patterns for file sizes.
  def self.parse_file_size str, output: :byte
    output = FILE_SIZES.keys.find{ |f| f == output || FILE_SIZES[f][:exp].include?(output.to_s.downcase) } || :byte
    bytes = 0.0
    FILE_SIZES.each do |k, v|
      v[:exp].each do |e|
        numbers = str.scan(/(?=\w|\D|\A)\d?\.?\d+[[:space:]]*#{e}(?=\W|\d|\z)/i)
        numbers.each{ |n| bytes+= n.to_f * v[:mult] }
      end
    end
    return bytes / FILE_SIZES[output][:mult]
  end

FILE_SIZES = {
    byte: { mult: 1, exp: ['b', 'byt', 'byte'] },
    kilobyte: { mult: 1024, exp: ['kb', 'kilo', 'k', 'kbyte', 'kilobtye'] },
    megabyte: { mult: 1048576, exp: ['mb', 'mega', 'm', 'mib', 'mbyte', 'megabtye'] },
    gigabyte: { mult: 1073741824, exp: ['gb', 'giga', 'g', 'gbyte', 'gigabtye'] },
    terabtye: { mult: 1099511627776, exp: ['tb', 'tera', 't', 'tbyte', 'terabtye'] },
    petabtye: { mult: 1125899906842624, exp: ['pb', 'peta', 'p', 'pbyte', 'petabtye'] },
    exabtye: { mult: 1152921504606846976, exp: ['eb', 'exa', 'e', 'ebyte', 'exabtye'] },
    zettabtye: { mult: 1180591620717411303424, exp: ['zb', 'zetta', 'z', 'zbyte', 'zettabtye'] },
    yottabtye: { mult: 1208925819614629174706176, exp: ['yb', 'yotta', 'y', 'ybyte', 'yottabtye'] }
  }

end

class File
  def dirname
    File.dirname(self.path)
  end
end

class String
  def to_file path, mkpath = true
    BBLib.string_to_file path, self, mkpath
  end

  def file_name with_extension = true
    self[(self.include?('/') ? self.rindex('/').to_i+1 : 0)..(with_extension ? -1 : self.rindex('.').to_i-1)]
  end

  def parse_file_size output: :byte
    BBLib.parse_file_size(self, output:output)
  end
end
