


module BBLib

  def self.cpu_used_p
    if BBLib.windows?
      `wmic cpu get loadpercentage /format:value`.extract_numbers.first
    elsif BBLib.linux?
      `top -bn2`.split("\n").find{|l| l.start_with?('%Cpu(s)')}.extract_numbers[0..2].inject(0){|sum, x| sum+=x.to_f }
    else
      nil
    end
  end

  def self.cpu_free_p
    100 - BBLib.cpu_used
  end

  def self.mem_total
    if BBLib.windows?
      `wmic computersystem get TotalPhysicalMemory`.extract_numbers.first
    elsif BBLib.linux?

    else
      nil
    end
  end

  def self.mem_used
    BBLib.mem_free.to_f - BBLib.mem_total.to_f
  end

  def self.mem_used_p
    (BBLib.mem_used.to_f / BBLib.mem_total.to_f) * 100.0
  end

  def self.mem_free
    if BBLib.windows?
      `wmic OS get FreePhysicalMemory /Value`.extract_numbers.first
    elsif BBLib.linux?

    else
      nil
    end
  end

  def self.mem_free_p
    (BBLib.mem_free.to_f / BBLib.mem_total.to_f) * 100.0
  end

end
