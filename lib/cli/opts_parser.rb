require_relative 'option'
require_relative '../error/opts_parser'
require_relative 'options/basic_option'

BBLib.scan_files(File.expand_path('../options', __FILE__), '*.rb') do |file|
  require_relative file
end

module BBLib
  class OptsParser
    include BBLib::Effortless

    attr_ary_of Option, :options, add_rem: true
    attr_str :usage, default: nil, allow_nil: true

    def usage(text = nil)
      @usage = text unless text.nil?
      @usage
    end

    def on(flag, *args, **opts, &block)
      flags = [flag] + args
      opts[:type] = :string unless opts[:type]
      add_options(opts.merge(flags: flags, processor: block))
    end

    def parse(*args)
      copy = [args].flatten.dup
      HashStruct.new.tap do |hash|
        options.each do |option|
          hash.deep_merge!(option.name => option.retrieve(copy))
        end
      end.merge(arguments: copy)
    end

    def help
      usage.to_s + "\n\t" +
      options.join("\n\t")
    end

    def to_s
      help
    end

    protected

    def method_missing(method, *args, &block)
      if Option.types.include?(method)
        define_singleton_method(method) do |flag, *args, **opts, &block|
          on(flag, *args, **opts.merge(type: method), &block)
        end
        send(method, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      Option.types.include?(method) || super
    end

  end
end
