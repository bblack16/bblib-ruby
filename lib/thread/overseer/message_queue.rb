module BBLib

  class MessageQueue
    attr_reader :queue, :thread, :mode, :duration, :started, :pause, :log

    def initialize mode: :puts, pause: 0.1, log: "#{Dir.pwd}/messages.log"
      @queue = []
      self.mode = mode
      self.pause = pause
      self.log = log
    end

    def mode= m
      @mode = m.is_a?(Proc) ? m : (DEFAULT_MODES.include?(m) ? m : :puts)
    end

    def log= path
      @log = path.to_s
    end

    def push message
      [message].flatten.each do |m|
        @queue.push m
      end
    end

    def unshift message
      [message].flatten.each do |m|
        @queue.unshift m
      end
    end

    def pause= p
      @pause = BBLib.keep_between(p, 0, nil)
    end

    def active?
      @thread.alive?
    end

    def start duration: nil
      started, pause = Time.now.to_f, @pause
      @thread = Thread.new{
        while duration.nil? || (Time.now.to_f - started < duration)
          while !@queue.empty?
            case @mode
            when :puts
              puts @queue.delete_at(0)
            when :p
              p @queue.delete_at(0)
            when :log
              (@queue.delete_at(0).to_s + "\n").to_file(@log)
            end
          end
          sleep(pause)
        end
      }
    end

    def restart duration: nil
      stop
      start duration:duration
    end

    def stop
      @thread.kill unless @thread.nil?
    end

    def clear
      @queue.clear
    end

    DEFAULT_MODES = {
      puts: proc{ |m| puts "#{m}\n" } ,
      p: proc{ |m| p "#{m}\n" },
      log: proc{ |m| "#{m}\n".to_file(@log) }
    }

  end

end
