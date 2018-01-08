require 'logger' unless BBLib::in_opal?

module BBLib

  def self.logger
    @logger ||= default_logger
  end

  def self.default_logger
    log = ::Logger.new(STDOUT)
    log.level = ::Logger::INFO
    log.formatter = proc do |severity, datetime, progname, msg|
      if msg.is_a?(Exception)
        msg = msg.inspect + "\n\t" + msg.backtrace.join("\n\t")
      end
      "[#{datetime}] #{severity} - #{msg}\n"
    end
    log.datetime_format = '%Y-%m-%d %H:%M:%S'
    log
  end

  def self.logger=(logger)
    raise ArgumentError, 'Must be set to a valid logger' unless logger.is_a?(Logger)
    @logger = logger
  end

  def self.enable_logger(enable = true)
    @logger_on = enable
  end

  def self.log_enabled?
    @logger_on
  end

  class << self
    [:fatal, :error, :warn, :info, :debug].each do |sev|
      define_method(sev) do |*args|
        logger.send(sev, *args)
      end
    end
  end

end
