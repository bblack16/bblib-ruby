module BBLib

  class Overseer
    attr_reader :threads, :max, :chains, :message_queue

    def initialize max: nil
      @threads, @chains = Hash.new, Hash.new
    end

    def create_chain name, *args
      raise "Invalid argument type" unless !args.any?{ |a| !(Proc === a) }
      @chains[name] = args.flatten
      @threads[name] = []
    end

    def call_chain name, *args
      return false unless @chains.include? name
      @threads[name] << Thread.new{ @chains[name].first.call(args) }
    end

    def active? name
      return @threads[name].any?{ |t| t.alive? }
    end

    def max= m
      @max = m.nil? ? nil : BBLib::keep_between(m, 1, nil)
    end


  end

end
