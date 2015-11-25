

module BBLib

  def self.scan_dir path, filter: nil, recursive: false
    puts path
    if filter.is_a? String then filters = [filters] end
    if !filter.nil? && filter.is_a?(Array)
      filter = filter.map{ |f| path.to_s + (recursive ? '/**/' : '/') + f.to_s }
    elsif !filter.nil? && filter.is_a?(String)
      filter = path.to_s + (recursive ? '/**/' : '/') + filter
    elsif filter.nil?
      filter = path.to_s + (recursive ? '/**/*' : '/*')
    end
    puts filter
    Dir.glob(filter)
  end

  def self.scan_files path, filter: nil, recursive: false
    BBLib.scan_dir(path, filter: filter, recursive: recursive).map{ |f| File.file?(f) ? File.new(f) : nil}.reject{ |r| r.nil? }
  end

  def self.scan_dirs path, filter: nil, recursive: false
    BBLib.scan_dir(path, filter: filter, recursive: recursive).map{ |f| File.directory?(f) ? Dir.new(f) : nil}.reject{ |r| r.nil? }
  end

  def self.string_to_file path, str, mkpath = true
    if !Dir.exists?(path) && mkpath
      FileUtils.mkpath File.dirname(path)
    end
    File.write(path, str.to_s)
  end

  def self.parse_file_size str, to = :B
    to = FILE_SIZES.keys.find{ |f| FILE_SIZES[f] == to.to_sym || FILE_SIZES[f][:exp].include?(to.to_s.downcase) } || :B
    bytes = 0.0
    FILE_SIZES.each do |k, v|
      v[:exp].each do |e|
        numbers = str.scan(/^.\d+#{e} /i) + str.scan(/^.\d+#{e}\z/i) + str.scan(/^.\d+ #{e} /i) + str.scan(/^.\d+ #{e}\z/i) + str.scan(/\d+.\d+#{e} /i) + str.scan(/\d+.\d+#{e}\z/i) + str.scan(/\d+.\d+ #{e} /i) + str.scan(/\d+.\d+ #{e}\z/i)
        numbers.each{ |n| bytes+= n.to_f * v[:mult] }
      end
    end
    return bytes / FILE_SIZES[to][:mult]
  end

  private

    FILE_SIZES = {
      B: { mult: 1, exp: ['b', 'byt', 'byte'] },
      KB: { mult: 1024, exp: ['kb', 'kilo', 'k', 'kbyte', 'kilobtye'] },
      MB: { mult: 1048576, exp: ['mb', 'mega', 'm', 'mib', 'mbyte', 'megabtye'] },
      GB: { mult: 1073741824, exp: ['gb', 'giga', 'g', 'gbyte', 'gigabtye'] },
      TB: { mult: 1099511627776, exp: ['tb', 'tera', 't', 'tbyte', 'terabtye'] },
      PB: { mult: 1125899906842624, exp: ['pb', 'peta', 'p', 'pbyte', 'petabtye'] },
      EB: { mult: 1152921504606846976, exp: ['eb', 'exa', 'e', 'ebyte', 'exabtye'] },
      ZB: { mult: 1180591620717411303424, exp: ['zb', 'zetta', 'z', 'zbyte', 'zettabtye'] },
      YB: { mult: 1208925819614629174706176, exp: ['yb', 'yotta', 'y', 'ybyte', 'yottabtye'] }
      # b: { mult: 1000 / 8, exp: [] },
      # Kb: { mult: 1000000 / 8, exp: [] },
      # Mb: { mult: 1000000000 / 8, exp: [] },
      # Gb: { mult: 1000000000000 / 8, exp: [] },
      # Tb: { mult: 1000000000000000 / 8, exp: [] },
      # Pb: { mult: 1000000000000000000 / 8, exp: [] },
      # Eb: { mult: 1000000000000000000000 / 8, exp: [] },
      # Zb: { mult: 1000000000000000000000000 / 8, exp: [] },
      # Yb: { mult: 1000000000000000000000000000 / 8, exp: [] }
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

  def parse_file_size to = :B
    BBLib.parse_file_size self, to
  end
end
