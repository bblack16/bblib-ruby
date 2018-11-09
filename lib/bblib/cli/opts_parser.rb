require_relative 'option'
require_relative 'exceptions/opts_parser'
require_relative 'options/basic_option'
require_relative 'options/string'
require_relative 'options/command'
require_relative 'options/bool'
require_relative 'options/date'
require_relative 'options/time'
require_relative 'options/float'
require_relative 'options/integer'
require_relative 'options/json'
require_relative 'options/regexp'
require_relative 'options/symbol'
require_relative 'options/toggle'
require_relative 'options/untoggle'
require_relative 'options/element_of'

module BBLib
  class OptsParser
    include BBLib::Effortless

    attr_ary_of Option, :options, add_rem: true
    attr_str :usage, default: nil, allow_nil: true

    def self.build(&block)
      new(&block)
    end

    def usage(text = nil)
      @usage = text unless text.nil?
      @usage
    end

    def at(position, **opts, &block)
      add_options(opts.merge(type: :at, position: position, processor: block))
    end

    def on(*flags, **opts, &block)
      opts[:type] = :string unless opts[:type]
      add_options(opts.merge(flags: flags, processor: block))
    end

    def parse(args = ARGV)
      parse!(args.dup)
    end

    def parse!(args = ARGV)
      args = [args] unless args.is_a?(Array)
      HashStruct.new.tap do |hash|
        options.sort_by { |opt| opt.position || 10**100 }.each do |option|
          option.retrieve(args, hash)
        end
      end.merge(arguments: args)
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
        define_singleton_method(method) do |*flags, **opts, &block|
          on(*flags, **opts.merge(type: method), &block)
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
