module BBLib
  module Command
    def self.quote(arg)
      arg =~ /\s+/ ? "\"#{arg}\"" : arg.to_s
    end
  end
end
