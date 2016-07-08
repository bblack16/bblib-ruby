


module BBLib
  module OS

    def self.cpu_usages
      if windows?
        {
          total: `wmic cpu get loadpercentage /format:value`.extract_numbers.first.to_f
        }
      elsif linux? || mac?
        system_stats[:cpu]
      else
        nil
      end
    end

    def self.uptime
      if windows?
        uptime = `net statistics server`.split("\n").find{|l| l.start_with?('Statistics since ')}.split(/since /i).last.strip
        Time.now - Time.strptime(uptime, '%m/%d/%Y %l:%M:%S %p')
      else
        `cat /proc/uptime`.extract_numbers.first
      end
    end

    def self.cpu_used_p
      cpu_usages[:total]
    end

    def self.cpu_free_p
      100 - cpu_used
    end

    def self.mem_total
      if windows?
        `wmic computersystem get TotalPhysicalMemory`.extract_numbers.first / 1024.0
      elsif linux?
        system_stats.hpath('memory.total')
      else
        nil
      end
    end

    def self.mem_used
      mem_total.to_f - mem_free.to_f
    end

    def self.mem_used_p
      (mem_used.to_f / mem_total.to_f) * 100.0
    end

    def self.mem_free
      if windows?
        `wmic os get freephysicalmemory /format:value`.extract_numbers.first
      elsif linux?
        system_stats.hpath('memory.free')
      else
        nil
      end
    end

    def self.mem_free_p
      (mem_free.to_f / mem_total.to_f) * 100.0
    end

    def self.system_stats
      if windows?
        memfree = mem_free
        memtotal = mem_total
        memused = memtotal - memfree
        {
          cpu: cpu_usages,
          memory: {
            free: memfree,
            used: memused,
            total: memtotal,
            free_p: (memfree / memtotal.to_f) * 100,
            used_p: (memused / memtotal.to_f) * 100
          },
          uptime: uptime
        }
      else
        stats = `top -b -n2 -d 0.1`.split("\n")
        cpu = stats.find_all{|l| l =~ /\A\%?Cpu\(s\)/i }.last.extract_numbers
        loads = stats.find_all{|l| l =~ / load average\: /i }.last.scan(/load average:.*/i).first.extract_numbers
        mem = stats.find_all{|l| l =~ /KiB Mem|Mem\:/i }.last.extract_numbers
        time = `cat /proc/uptime`.extract_numbers
        {
          cpu: {
            user: cpu[0],
            system: cpu[1],
            nice: cpu[2],
            total: cpu[0..2].inject(0){ |sum, v| sum += v.to_f },
            idle: cpu[3],
            wait: cpu[4],
            hardware_interrupts: cpu[5],
            software_interrupts: cpu[6],
            hypervisor: cpu[7]
          },
          uptime: time[0],
          uptime_idle: time[1],
          memory: {
            free: mem[1],
            used: mem[2],
            total: mem[0],
            cache: mem[3],
            free_p: (mem[1] / mem[0].to_f) * 100,
            used_p: (mem[2] / mem[0].to_f) * 100
          },
          load_average: {
            1 => loads[0],
            5 => loads[1],
            15 => loads[2]
          }
        }
      end
    end

    def self.processes
      if windows?
        tasks = `tasklist /v`
        cpu = `wmic path win32_perfformatteddata_perfproc_process get PercentProcessorTime,percentusertime,IDProcess /format:list`
        cpu = cpu.split("\n\n\n\n").reject(&:empty?)
              .map{ |l| l.scan(/\d+/).map(&:to_i)}
              .map{ |n|[ n[0], {cpu: n[1], user: n[2] }]}.to_h
        lines = tasks.split("\n")[3..-1].map{ |l| l.split(/\s{2,}/) }
        mem = mem_total
        cmds = `wmic process get processid,commandline /format:csv`.split("\n")[1..-1].reject{ |r| r.strip  == ''}.map{ |l| l.split(',')[1..-1] }.map{ |l| [l.last.to_i, l[0..-2].join(',')]}.to_h
        lines.map do |l|
          pid = l[1].extract_numbers.first
          {
            name: l[0],
            pid: pid,
            user: l[4],
            mem: (((l[3].gsub(',', '').extract_numbers.first / mem_total) * 100) rescue nil),
            cpu: (cpu[pid][:cpu] rescue nil),
            cmd: cmds[pid]
          }
        end
      else
        t = `ps -e -o comm,pid,ruser,%cpu,%mem,cmd`
        lines = t.split("\n")[1..-1].map{ |l| l.split(/\s+/) }
        lines.map{ |l| l.size == 6 ? l : [l[0], l[1], l[2], l[3], l[4], l[5..-1].join(' ')] }
        lines.map do |l|
          {
            name: l[0],
            pid: l[1].to_i,
            user: l[2],
            cpu: l[3].to_f,
            mem: l[4].to_f,
            cmd: l[5]
          }
        end
      end
    end

    def self.filesystems
      if windows?
        types = {
          0 => 'Unknown',
          1 => 'No Root Directory',
          2 => 'Removable Disk',
          3 => 'Local Disk',
          4 => 'Network Drive',
          5 => 'Compact Disc',
          6 => 'RAM Disk'
        }
        parse_wmic('wmic logicaldisk get name,description,filesystem,freespace,size,volumename,volumeserialnumber,providername,drivetype')
          .map do |v|
            v.hpath_move(
              'freespace'          => 'free',
              'providername'       => 'provider',
              'volumename'         => 'volume_name',
              'volumeserialnumber' => 'serial_number',
              'filesystem'         => 'filesystem_type',
              'name'               => 'disk'
            )
            dt = v.delete(:drivetype).to_i
            v[:type] = types[dt]
            if (2..4) === dt
              v[:free] = v[:free].to_i
              v[:size] = v[:size].to_i
              v[:used] = v[:size] - v[:free]
              v[:free_p] = (v[:free] / v[:size].to_f) * 100
              v[:used_p] = (v[:used] / v[:size].to_f) * 100
            end
            v
          end
      else
        `df -aTB 1`
          .split("\n")[1..-1]
          .map{ |l| l.split(/\s{2,}|(?<=\d)\s|(?<=%)\s|(?<=\-)\s|(?<=\w)\s+(?=\w+\s+\d)/)}
          .map do |i|
            {
              filesystem: i[0],
              type:       i[1],
              size:       i[2].to_i,
              used:       i[3].to_i,
              available:  i[4].to_i,
              used_p:     i[5].extract_integers.first.to_f,
              mount:      i[6],
            }
          end
      end
    end
  end
end
