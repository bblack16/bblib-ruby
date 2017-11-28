module BBLib
  module Logger

    def logger
      self.class.logger
    end

    # [:debug, :info, :warn, :error, :fatal, :unknown].each do |sev|
    #   define_method(sev) do |msg = nil, &block|
    #       logger.send(sev) { "[#{self.class}] #{msg ? msg : block.call}" }
    #   end
    # end

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def logger
        BBLib.logger
      end

      # [:debug, :info, :warn, :error, :fatal, :unknown].each do |sev|
      #   define_method(sev) do |msg = nil, &block|
      #       logger.send(sev) { "[#{self}] #{msg ? msg : block.call}" }
      #   end
      # end
    end

  end
end
