
module BBLib
  # Takes one or more strings and normalizes slashes to create a consistent file path
  # Useful when concating two strings that when you don't know if one or both will end or begin with a slash
  def self.pathify(*strings)
    (strings.first.start_with?('/', '\\') ? strings.first.scan(/^[\/\\]{1,2}/).first : '') + strings.map(&:to_s).msplit('/', '\\').map(&:strip).join('/')
  end

  # Scan for files and directories. Can be set to be recursive and can also have filters applied.
  # @param [String] path The directory to scan files from.
  # @param [String..., Regexp...] filters A list of filters to apply. Can be regular expressions or strings.
  #  Strings with a * are treated as regular expressions with a .*. If no filters are passed, all files/dirs are returned.
  # @param [Boolean] recursive When true scan will recursively search directories
  # @param [Boolean] files If true, paths to files matching the filter will be returned.
  # @param [Boolean] dirs If true, paths to dirs matching the filter will be returned.
  # @param [Array] exclude Can be an array of regular expressions or strings that should be ignored when scanning. * in a string is expanded into .*, but all other characters are literal.
  def self.scan_dir(path, *filters, recursive: false, files: true, dirs: true, exclude: [], filter_base: true, &block)
    return [] unless Dir.exist?(path)
    filters = filters.map { |filter| filter.is_a?(Regexp) ? filter : /^#{Regexp.quote(filter).gsub('\\*', '.*')}$/ }
    exclude = exclude ? [exclude].flatten.map { |exp| exp.is_a?(Regexp) ? exp : /^#{Regexp.quote(exp).gsub('\\*', '.*')}$/ } : []
    Dir.foreach(path).flat_map do |item|
      next if item =~ /^\.{1,2}$/ || (!exclude.empty? && exclude.any? { |exp| item =~ exp })
      item = "#{path}/#{item}".gsub('\\', '/')
      if File.file?(item)
        if files && (filters.empty? || filters.any? { |filter| item =~ filter || filter_base && item.file_name =~ filter })
          block_given? ? yield(item) : item
        end
      elsif File.directory?(item)
        recur = recursive ? scan_dir(item, *filters, recursive: recursive, exclude: exclude, files: files, dirs: dirs, &block) : []
        if dirs && (filters.empty? || filters.any? { |filter| item =~ filter || filter_base && item.file_name =~ filter })
          (block_given? ? yield(item) : [item] + recur)
        elsif recursive
          recur
        end
      end
    end.compact
  end

  # Uses BBLib.scan_dir but returns only files
  def self.scan_files(path, *filters, recursive: false, exclude: [], filter_base: true, &block)
    scan_dir(path, *filters, recursive: recursive, dirs: false, exclude: exclude, filter_base: filter_base, &block)
  end

  # Uses BBLib.scan_dir but returns only directories.
  def self.scan_dirs(path, *filters, recursive: false, exclude: [], filter_base: true, &block)
    scan_dir(path, *filters, recursive: recursive, files: false, exclude: exclude, filter_base: filter_base, &block)
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
    output = FILE_SIZES.keys.find { |fs| fs == output || FILE_SIZES[fs][:exp].include?(output.to_s.downcase) } || :byte
    bytes = 0.0
    FILE_SIZES.each do |_k, v|
      v[:exp].each do |exp|
        str.scan(/(?=\w|\D|^)\d*\.?\d+\s*#{exp}s?(?=\W|\d|$)/i)
           .each { |num| bytes += num.to_f * v[:mult] }
      end
    end
    bytes / FILE_SIZES[output][:mult]
  end

  # Takes an integer or float and converts it into a string that represents
  #   a file size (e.g. "5 MB 156 kB")
  # @param [Integer, Float] num The number of bytes to convert to a file size string.
  # @param [Symbol] input Sets the value of the input. Default is byte.
  # @param [Symbol] stop Sets a minimum file size to display.
  #   e.g. If stop is set to :megabyte, :kilobyte and below will be truncated.
  # @param [Symbol] style The out style, Current options are :short and :long
  def self.to_file_size(num, input: :byte, stop: :byte, style: :short)
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

  # Basic detection for whether or not a file is binary or not
  def self.binary?(file, bytes: 1024, ctrl_threshold: 0.5, binary_threshold: 0.05)
    ascii  = 0
    ctrl   = 0
    binary = 0

    read_bytes = File.open(file, 'rb') { |io| io.read(bytes) }

    return false if read_bytes.nil? || read_bytes.empty?

    read_bytes.each_byte do |byte|
      case byte
      when 0..31
        ctrl += 1
      when 32..127
        ascii += 1
      else
        binary += 1
      end
    end

    ctrl.to_f / ascii > ctrl_threshold || binary.to_f / ascii > binary_threshold
  end
end

# Monkey patches for the Numeric class
class Numeric
  def to_file_size(*args)
    BBLib.to_file_size(self, *args)
  end
end

# Monkey patches for the String class
class String
  def to_file(*args)
    BBLib.string_to_file(self, *args)
  end

  def file_name(with_extension = true)
    with_extension ? File.basename(self) : File.basename(self, File.extname(self))
  end

  def dirname
    File.dirname(self)
  end

  def parse_file_size(*args)
    BBLib.parse_file_size(self, *args)
  end

  def pathify
    BBLib.pathify(self)
  end
end
