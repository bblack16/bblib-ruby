

module BBLib
  # Adds type casted attr getters and setters with all kinds of other goodness to ensure
  # classes accept, set and return data the correct way without requiring piles or boiler plate
  # code.
  module Attrs

    def _attrs
      @_attrs ||= {}
    end

    # Lists all attr_* getter methods that were created on this class.
    def instance_readers
      _attrs.map { |k, v| [:attr_writer].any? { |t| v[:type] == t } ? nil : k }.compact
    end

    # Lists all attr_* setter methods that were created on this class.
    def instance_writers
      _attrs.keys.map { |m| "#{m}=".to_sym }.select { |m| method_defined?(m) }
    end

    def attr_reader(*args)
      args.each { |arg| _register_attr(arg, :attr_reader) }
      super(*args)
    end

    def attr_writer(*args)
      args.each { |arg| _register_attr(arg, :attr_writer) }
      super(*args)
    end

    def attr_accessor(*args)
      args.each { |arg| _register_attr(arg, :attr_accessor) }
      super(*args)
    end

    def attr_custom(method, opts = {}, &block)
      called_by = caller_locations(1,1)[0].label.gsub('block in ', '')
      type      = (type =~ /^attr_/ ? called_by.sub('attr_', '').to_sym : :custom)
      opts      = opts.dup
      ivar      = "@#{method}".to_sym

      define_method("#{method}=") do |*args|
        args = opts[:pre_proc].call(*args) if opts[:pre_proc]
        instance_variable_set(ivar, yield(*args))
      end

      define_method(method) do
        if instance_variable_defined?(ivar)
          instance_variable_get(ivar)
        elsif opts.include?(:default)
          send("#{method}=", opts[:default])
        end
      end

      protected method if opts[:protected] || opts[:protected_reader]
      protected "#{method}=".to_sym if opts[:protected] || opts[:protected_writer]
      private method if opts[:private] || opts[:private_reader]
      private "#{method}=".to_sym if opts[:private] || opts[:private_writer]
      _register_attr(method, type, opts)
    end

    def attr_of(klasses, *methods, **opts)
      allowed = [klasses].flatten
      methods.each do |method|
        attr_custom(method, opts.merge(_attr_type: :of)) do |arg|
          if BBLib.is_a?(arg, *allowed) || (arg.nil? && opts[:allow_nil])
            arg
          else
            raise ArgumentError, "#{method} must be set to a class of #{allowed.join_terms(:or)}, NOT #{arg.class}"
          end
        end
      end
    end

    def attr_string(*methods, **opts)
      methods.each do |method|
        attr_custom(method, opts) { |arg| arg.nil? && opts[:allow_nil] ? arg : arg.to_s }
      end
    end

    def attr_integer(*methods, **opts)
      methods.each do |method|
        attr_custom(method, opts) { |arg| arg.nil? && opts[:allow_nil] ? arg : arg.to_i }
      end
    end

    def attr_float(*methods, **opts)
      methods.each do |method|
        attr_custom(method, opts) { |arg| arg.nil? && opts[:allow_nil] ? arg : arg.to_f }
      end
    end

    def attr_symbol(*methods, **opts)
      methods.each do |method|
        attr_custom(method, opts) { |arg| arg.nil? && opts[:allow_nil] ? arg : arg.to_s.to_sym }
      end
    end

    def attr_boolean(*methods, **opts)
      methods.each do |method|
        attr_custom(method, opts) { |arg| arg ? true : false }
        alias_method "#{method}?", method unless opts[:no_?]
      end
    end

    alias attr_bool attr_boolean

    def attr_integer_between(min, max, *methods, **opts)
      methods.each do |method|
        attr_custom(method, opts) { |arg| BBLib.keep_between(arg, min, max) }
      end
    end

    def attr_integer_loop(min, max, *methods, **opts)
      methods.each do |method|
        attr_custom(method, opts) { |arg| BBLib.loop_between(arg, min, max) }
      end
    end

    def attr_element_of(list, *methods, **opts)
      methods.each do |method|
        attr_custom(method, opts) do |arg|
          raise ArgumentError, "Invalid option '#{arg}' for #{method}." unless list.include?(arg) || (opts[:allow_nil] && arg.nil?)
          arg
        end
      end
    end

    def attr_array(*methods, **opts)
      methods.each do |method|
        attr_custom(method, opts) do |arg|
          args = arg.is_a?(Array) ? arg : [arg]
          args = args.uniq if opts[:uniq]
          args
        end
        attr_array_adder(method, opts[:adder_name]) if opts[:add_rem] || opts[:adder]
        attr_array_remover(method, opts[:remover_name]) if opts[:add_rem] || opts[:remover]
      end
    end

    def attr_array_of(klasses, *methods, **opts)
      klasses = [klasses].flatten
      methods.each do |method|
        attr_custom(method, opts) do |args|
          args = [args] unless args.is_a?(Array)
          array = []
          args.each do |arg|
            match = BBLib.is_a?(arg, *klasses)
            raise ArgumentError, "Invalid class passed to #{method}: #{arg.class}. Must be a #{klasses.join_terms(:or)}." unless match || opts[:raise] == false
            array.push(arg) if match
          end
          array
        end
        attr_array_adder(method, opts[:adder_name]) if opts[:add_rem] || opts[:adder]
        attr_array_remover(method, opts[:remover_name]) if opts[:add_rem] || opts[:remover]
      end
    end

    def attr_array_adder(method, name = nil, &block)
      name = "add_#{method}" unless name
      define_method(name) do |*args|
        array = send(method)
        args.each do |arg|
          arg = yield(arg) if block_given?
          array.push(arg)
        end
        send("#{method}=", array)
      end
    end

    def attr_array_remover(method, name = nil)
      name = "remove_#{method}" unless name
      define_method(name) do |*args|
        array = instance_variable_get("@#{method}")
        args.map do |arg|
          next unless array && !array.empty?
          array.delete(arg)
        end
      end
    end

    def attr_file(*methods, **opts)
      methods.each do |method|
        attr_custom(method, opts) do |arg|
          exists = File.exist?(arg.to_s)
          if !exists && opts[:mkfile] && arg
            FileUtils.touch(arg.to_s)
            exists = File.exist?(arg.to_s)
          end
          raise ArgumentError, "#{method} must be set to a valid file. '#{arg}' cannot be found." unless exists || (opts[:allow_nil] && arg.nil?)
          arg
        end
      end
    end

    def attr_dir(*methods, **opts)
      methods.each do |method|
        attr_custom(method, opts) do |arg|
          exists = Dir.exist?(arg.to_s)
          if !exists && (opts[:mkdir] || opts[:mkpath]) && arg
            FileUtils.mkpath(arg.to_s)
            exists = Dir.exist?(arg.to_s)
          end
          raise ArgumentError, "#{method} must be set to a valid directory. '#{arg}' cannot be found." unless exists || (opts[:allow_nil] && arg.nil?)
          arg
        end
      end
    end

    def attr_time(*methods, **opts)
      methods.each do |method|
        attr_custom(method, **opts) do |arg|
          if opts[:formats]
            arg = arg.to_s
            opts[:format].each do |format|
              arg = Time.strftime(arg, format) rescue arg
            end
          end
          if arg.is_a?(Time) || arg.nil? && opts[:allow_nil]
            arg
          elsif arg.is_a?(Numeric)
            Time.at(arg)
          else
            Time.parse(arg.to_s)
          end
        end
      end
    end

    def attr_hash(*methods, **opts)
      methods.each do |method|
        attr_custom(method, **opts) do |arg|
          raise ArgumentError, "#{method} must be set to a hash, not a #{arg.class}." unless arg.is_a?(Hash)
          if opts[:keys]
            arg.keys.each do |key|
              next if BBLib.is_a?(key, *opts[:keys])
              raise ArgumentError, "Invalid key type for #{method}: #{key.class}"
            end
          end
          if opts[:values]
            arg.values.each do |value|
              next if BBLib.is_a?(value, *opts[:values])
              raise ArgumentError, "Invalid value type for #{method}: #{value.class}"
            end
          end
          arg
        end
      end
    end

    protected

    def _register_attr(method, type, opts = {})
      _attrs[method] = { type: type, options: opts }
      method
    end

  end
end
