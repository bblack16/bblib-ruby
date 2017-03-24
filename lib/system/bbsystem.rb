module BBLib
  # A useable string representation of the command line that evoked this ruby instance (platform agnostic)
  def self.command_line(*args, include_args: true, include_ruby: true, prefix: nil, suffix: nil)
    args = ARGV if args.empty?
    "#{prefix}#{include_ruby ? Command.quote(Gem.ruby) : nil} #{Command.quote($0)}" \
    " #{include_args ? args.map { |a| Command.quote(a) }.join(' ') : nil}#{suffix}"
      .strip
  end

  # EXPERIMENTAL: Reloads the original file that was called
  def self.reload(include_args: true)
    load "#{command_line(*args, include_ruby: false, include_args: false)}"
  end

  # EXPERIMENTAL: Restart the ruby process that is currently running.
  def self.restart(*args, include_args: true, stay_alive: 1)
    exit(0)
  rescue SystemExit
    opts = BBLib::OS.windows? ? { new_pgroup: true } : { pgroup: true }
    pid = spawn(command_line(*args, include_args: include_args, prefix: (BBLib::OS.windows? ? 'start ' : nil)), **opts)
    Process.detach(pid)
    sleep(stay_alive)
  end

  module Command
    def self.quote(arg)
      arg =~ /\s+/ ? "\"#{arg}\"" : arg.to_s
    end
  end

end
