
module BBLib
  # Takes one or more strings and normalizes slashes to create a consistent file path
  # Useful when concating two strings that when you don't know if one or both will end or begin with a slash
  def self.pathify(*strings)
    (strings.first.start_with?('/', '\\') ? '/' : '') + strings.map(&:to_s).msplit('/', '\\').map(&:strip).join('/')
  end

  # Scan for files and directories. Can be set to be recursive and can also have filters applied.
  def self.scan_dir(path = Dir.pwd, *filters, recursive: false, &block)
    filters = [''] if filters.empty?
    Dir.glob(filters.flat_map { |f| "#{path}/#{recursive ? '/**/*' : '/*'}#{f}".pathify }, &block)
  end

  # Uses BBLib.scan_dir but returns only files
  def self.scan_files(*args)
    BBLib.scan_dir(*args).select { |f| File.file?(f) }
  end

  # Uses BBLib.scan_dir but returns only directories.
  def self.scan_dirs(*args)
    BBLib.scan_dir(*args).select { |f| File.directory?(f) }
  end

  # Shorthand method to write a string to disk. By default the
  # path is created if it doesn't exist.
  # Set mode to w to truncate file or leave at a to append.
  def self.string_to_file(str, path, mkpath: true, mode: 'a')
    FileUtils.mkpath(File.dirname(path)) if mkpath && !Dir.exist?(path)
    File.write(path, str.to_s, mode: mode)
  end

  # A file size parser for strings. Extracts any known patterns for file sizes.
  def self.parse_file_size(str, output: :byte)
    output = FILE_SIZES.keys.find { |f| f == output || FILE_SIZES[f][:exp].include?(output.to_s.downcase) } || :byte
    bytes = 0.0
    FILE_SIZES.each do |_k, v|
      v[:exp].each do |e|
        str.scan(/(?=\w|\D|^)\d*\.?\d+\s*#{e}s?(?=\W|\d|$)/i)
           .each { |n| bytes+= n.to_f * v[:mult] }
      end
    end
    bytes / FILE_SIZES[output][:mult]
  end

  FILE_SIZES = {
    byte:      { mult: 1, exp: %w(b byt byte) },
    kilobyte:  { mult: 1024, exp: %w(kb kilo k kbyte kilobyte) },
    megabyte:  { mult: 1024**2, exp: %w(mb mega m mib mbyte megabyte) },
    gigabyte:  { mult: 1024**3, exp: %w(gb giga g gbyte gigabyte) },
    terabyte:  { mult: 1024**4, exp: %w(tb tera t tbyte terabyte) },
    petabyte:  { mult: 1024**5, exp: %w(pb peta p pbyte petabyte) },
    exabyte:   { mult: 1024**6, exp: %w(eb exa e ebyte exabyte) },
    zettabyte: { mult: 1024**7, exp: %w(zb zetta z zbyte zettabyte) },
    yottabyte: { mult: 1024**8, exp: %w(yb yotta y ybyte yottabyte) }
  }.freeze
end

class File
  def dirname
    File.dirname(path)
  end
end

class String
  def to_file(*args)
    BBLib.string_to_file(self, *args)
  end

  def file_name(with_extension = true)
    self[(include?('/') ? rindex('/').to_i+1 : 0)..(with_extension ? -1 : rindex('.').to_i-1)]
  end

  def dirname
    scan(/.*(?=\/)/).first
  end

  def parse_file_size(*args)
    BBLib.parse_file_size(self, *args)
  end

  def pathify
    BBLib.pathify(self)
  end
end
