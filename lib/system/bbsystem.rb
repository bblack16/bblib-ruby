module BBLib
  # A useable string representation of the command line that evoked this ruby instance (platform agnostic)
  def self.cmd_line(*args, include_args: true, include_ruby: true, prefix: nil, suffix: nil)
    args = ARGV if args.empty?
    include_ruby = false if special_program?
    "#{prefix}#{include_ruby ? Command.quote(Gem.ruby) : nil} #{Command.quote($PROGRAM_NAME)}" \
    " #{include_args ? args.map { |a| Command.quote(a) }.join(' ') : nil}#{suffix}"
      .strip
  end

  # EXPERIMENTAL: Reloads the original file that was called
  # Use at your own risk, this could cause some weird issues
  def self.reload(include_args: true)
    return false if special_program?
    load cmd_line(*args, include_ruby: false, include_args: include_args)
  end

  # EXPERIMENTAL: Restart the ruby process that is currently running.
  # Use at your own risk
  def self.restart(*args, include_args: true, stay_alive: 1)
    exit(0)
  rescue SystemExit
    opts = BBLib::OS.windows? ? { new_pgroup: true } : { pgroup: true }
    pid = spawn(cmd_line(*args, include_args: include_args, prefix: (BBLib::OS.windows? ? 'start ' : nil)), **opts)
    Process.detach(pid)
    sleep(stay_alive)
    exit(0) if special_program?
  end

  SPECIAL_PROGRAMS = ['pry', 'irb.cmd', 'irb'].freeze

  def self.special_program?
    SPECIAL_PROGRAMS.include?($PROGRAM_NAME)
  end

  module Command
    def self.quote(arg)
      arg =~ /\s+/ ? "\"#{arg}\"" : arg.to_s
    end
  end

end
