
module BBLib
  # Takes one or more strings and normalizes slashes to create a consistent file path
  # Useful when concating two strings that when you don't know if one or both will end or begin with a slash
  def self.pathify(*strings)
    (strings.first.start_with?('/', '\\') ? '/' : '') + strings.map(&:to_s).msplit('/', '\\').map(&:strip).join('/')
  end

  # Scan for files and directories. Can be set to be recursive and can also have filters applied.
  def self.scan_dir(path, *filters, recursive: false, files: true, dirs: true, &block)
    filters = filters.map { |f| f.is_a?(Regexp) ? f : /^#{Regexp.quote(f).gsub('\\*', '.*')}$/ }
    Dir.foreach(path).flat_map do |item|
      next if item =~ /^\.{1,2}$/
      item = "#{path}/#{item}"
      if File.file?(item)
        (block_given? ? yield(item) : item) if files && (filters.empty? || filters.any? { |f| item =~ f })
      elsif File.directory?(item)
        recur = recursive ? scan_dir(item, *filters, recursive: recursive, files: files, dirs: dirs, &block) : []
        if dirs && (filters.empty? || filters.any? { |f| item =~ f })
          (block_given? ? yield(item) : [item] + recur)
        elsif recursive
          recur
        end
      end
    end.compact
  end

  # Uses BBLib.scan_dir but returns only files
  def self.scan_files(path, *filters, recursive: false, &block)
    scan_dir(path, *filters, recursive: recursive, dirs: false, &block)
  end

  # Uses BBLib.scan_dir but returns only directories.
  def self.scan_dirs(path, *filters, recursive: false, &block)
    scan_dir(path, *filters, recursive: recursive, files: false, &block)
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

  def self.to_file_size(num, input: :byte, stop: :byte, style: :medium)
    return nil unless num.is_a?(Numeric)
    return '0' if num.zero?
    style = :short unless [:long, :short].include?(style)
    expression = []
    n = num * FILE_SIZES[input.to_sym][:mult]
    done = false
    FILE_SIZES.reverse.each do |k, v|
      next if done
      done = true if k == stop
      div = n / v[:mult]
      next unless div >= 1
      val = (done ? div.round : div.floor)
      expression << "#{val}#{v[:styles][style]}#{val > 1 && style != :short ? 's' : nil}"
      n -= val.to_f * v[:mult]
    end
    expression.join(' ')
  end

  FILE_SIZES = {
    byte:      { mult: 1, exp: %w(b byt byte), styles: { short: 'B', long: ' byte' } },
    kilobyte:  { mult: 1024, exp: %w(kb kilo k kbyte kilobyte), styles: { short: 'kB', long: ' kilobyte' } },
    megabyte:  { mult: 1024**2, exp: %w(mb mega m mib mbyte megabyte), styles: { short: 'MB', long: ' megabyte' } },
    gigabyte:  { mult: 1024**3, exp: %w(gb giga g gbyte gigabyte), styles: { short: 'GB', long: ' gigabyte' } },
    terabyte:  { mult: 1024**4, exp: %w(tb tera t tbyte terabyte), styles: { short: 'TB', long: ' terabyte' } },
    petabyte:  { mult: 1024**5, exp: %w(pb peta p pbyte petabyte), styles: { short: 'PB', long: ' petabyte' } },
    exabyte:   { mult: 1024**6, exp: %w(eb exa e ebyte exabyte), styles: { short: 'EB', long: ' exabyte' } },
    zettabyte: { mult: 1024**7, exp: %w(zb zetta z zbyte zettabyte), styles: { short: 'ZB', long: ' zettabyte' } },
    yottabyte: { mult: 1024**8, exp: %w(yb yotta y ybyte yottabyte), styles: { short: 'YB', long: ' yottabyte' } }
  }.freeze
end

class File
  def dirname
    File.dirname(path)
  end
end

class Numeric
  def to_file_size(*args)
    BBLib.to_file_size(self, *args)
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
