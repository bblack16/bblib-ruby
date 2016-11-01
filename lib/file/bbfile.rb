
module BBLib
  # Takes one or more strings and normalizes slashes to create a consistent file path
  # Useful when concating two strings that when you don't know if one or both will end or begin with a slash
  def self.pathify(*strings)
    start = strings.first.start_with?('/', '\\')
    (start ? '/' : '') + strings.map(&:to_s).msplit('/', '\\').map(&:strip).join('/')
  end

  # Scan for files and directories. Can be set to be recursive and can also have filters applied.
  def self.scan_dir(path = Dir.pwd, filter: nil, recursive: false)
    filter = if !filter.nil?
               [filter].flatten.map { |f| path.to_s + (recursive ? '/**/' : '/') + f.to_s }
             else
               (path.to_s + (recursive ? '/**/*' : '/*')).gsub('//', '/')
             end
    Dir.glob(filter)
  end

  # Uses BBLib.scan_dir but returns only files
  def self.scan_files(path, filter: nil, recursive: false)
    BBLib.scan_dir(path, filter: filter, recursive: recursive)
         .map { |f| f if File.file?(f) }.compact
  end

  # Uses BBLib.scan_dir but returns only directories.
  def self.scan_dirs(path, filter: nil, recursive: false)
    BBLib.scan_dir(path, filter: filter, recursive: recursive)
         .map { |d| d if File.directory?(d) }.compact
  end

  # Shorthand method to write a string to disk. By default the
  # path is created if it doesn't exist.
  # Set mode to w to truncate file or leave at a to append.
  def self.string_to_file(path, str, mkpath = true, mode: 'a')
    FileUtils.mkpath File.dirname(path) if !Dir.exist?(path) && mkpath
    File.write(path, str.to_s, mode: mode)
  end

  # A file size parser for strings. Extracts any known patterns for file sizes.
  def self.parse_file_size(str, output: :byte)
    output = FILE_SIZES.keys.find { |f| f == output || FILE_SIZES[f][:exp].include?(output.to_s.downcase) } || :byte
    bytes = 0.0
    FILE_SIZES.each do |_k, v|
      v[:exp].each do |e|
        numbers = str.scan(/(?=\w|\D|^)\d*\.?\d+\s*#{e}s?(?=\W|\d|$)/i)
        numbers.each { |n| bytes+= n.to_f * v[:mult] }
      end
    end
    bytes / FILE_SIZES[output][:mult]
  end

  FILE_SIZES = {
    byte:      { mult: 1, exp: %w(b byt byte) },
    kilobyte:  { mult: 1024, exp: %w(kb kilo k kbyte kilobyte) },
    megabyte:  { mult: 1_048_576, exp: %w(mb mega m mib mbyte megabyte) },
    gigabyte:  { mult: 1_073_741_824, exp: %w(gb giga g gbyte gigabyte) },
    terabyte:  { mult: 1_099_511_627_776, exp: %w(tb tera t tbyte terabyte) },
    petabyte:  { mult: 1_125_899_906_842_624, exp: %w(pb peta p pbyte petabyte) },
    exabyte:   { mult: 1_152_921_504_606_846_976, exp: %w(eb exa e ebyte exabyte) },
    zettabyte: { mult: 1_180_591_620_717_411_303_424, exp: %w(zb zetta z zbyte zettabyte) },
    yottabyte: { mult: 1_208_925_819_614_629_174_706_176, exp: %w(yb yotta y ybyte yottabyte) }
  }.freeze
end

class File
  def dirname
    File.dirname(path)
  end
end

class String
  def to_file(path, mkpath = true, mode: 'a')
    BBLib.string_to_file path, self, mkpath, mode: mode
  end

  def file_name(with_extension = true)
    self[(include?('/') ? rindex('/').to_i+1 : 0)..(with_extension ? -1 : rindex('.').to_i-1)]
  end

  def dirname
    scan(/.*(?=\/)/).first
  end

  def parse_file_size(output: :byte)
    BBLib.parse_file_size(self, output: output)
  end

  def pathify
    BBLib.pathify(self)
  end
end
