

module BBLib

  def self.scan_dir path, filter: nil, recursive: false
    if filter.is_a? String then filters = [filters] end
    if !filter.nil? && filter.is_a?(Array)
      filter = filter.map{ |f| path.to_s + (recursive ? '/**/' : '/') + f.to_s }
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

end

class File
  def dirname
    File.dirname(self.path)
  end
end

class String
  def to_file path, mkpath = true
    BBFile.string_to_file path, self, mkpath
  end

  def file_name with_extension = true
    self[(self.include?('/') ? self.rindex('/').to_i+1 : 0)..(with_extension ? -1 : self.rindex('.').to_i-1)]
  end
end
