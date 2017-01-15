module BBLib
  module Attr
    def attrs
      ancestors.reverse.each_with_object({}) do |klass, hash|
        hash.merge!(klass._attrs) if klass.respond_to?(:_attrs)
      end
    end

    def _attrs
      @_attrs ||= {}
    end

    private

    def _register_attr(method, type, opts = {})
      _attrs[method] = { type: type, options: opts }
    end

    def attr_type(method, opts, &block)
      opts = opts.dup
      define_method("#{method}=", &block)
      define_method(method) { instance_variable_get("@#{method}") }
      if opts.include?(:default)
        define_method("__reset_#{method}".to_sym) { send("#{method}=", opts[:default]) }
      end
      if opts[:serialize] && respond_to?(:_serialize_fields)
        _serialize_fields[method.to_sym] = { always: opts[:always], ignore: opts[:ignore] || (opts[:default].dup rescue opts[:default]) }
      end
      nil
    end

    def attr_sender(call, *methods, **opts)
      methods.each do |m|
        attr_type(
          m,
          opts,
          &attr_set(
            m,
            opts.merge(sender: true)
          ) { |x| x.nil? && opts[:allow_nil] ? nil : x.send(call) }
        )
      end
    end

    def attr_of(klass, *methods, **opts)
      methods.each do |m|
        attr_type(m, opts, &attr_set(m, opts) do |x|
                              x = attr_serialize(x, *klass) unless opts[:to_serialize_only]
                              if klass.is_a?(Array) ? klass.include?(x.class) : x.is_a?(klass)
                                instance_variable_set("@#{m}", x)
                              else
                                raise ArgumentError, "#{m} must be set to a #{klass} NOT #{x.class}."
                              end
                            end)
        _register_attr(m, :of, opts.merge(class: klass))
      end
    end

    def attr_serialize(hash, *klasses)
      if !klasses.include?(hash.class) && hash.is_a?(Hash)
        klasses.first.new(hash)
      else
        hash
      end
    end

    def attr_boolean(*methods, **opts)
      methods.each do |m|
        attr_type(m, opts) do |x|
          instance_variable_set("@#{m}", x && x.to_s != 'false' ? true : false)
        end
        alias_method "#{m}?", m unless opts[:no_q]
        _register_attr(m, :bool, opts)
      end
    end

    alias attr_bool attr_boolean

    def attr_string(*methods, **opts)
      attr_sender :to_s, *methods, opts
      methods.each { |m| _register_attr(m, :string, opts) }
    end

    alias attr_str attr_string
    alias attr_s attr_string

    def attr_integer(*methods, **opts)
      opts[:pre_proc] = [proc { |x| x == '' ? nil : x }, opts[:pre_proc]].flatten.compact
      attr_sender :to_i, *methods, opts
      methods.each { |m| _register_attr(m, :int, opts) }
    end

    alias attr_int attr_integer
    alias attr_i attr_integer

    def attr_float(*methods, **opts)
      opts[:pre_proc] = [proc { |x| x == '' ? nil : x }, opts[:pre_proc]].flatten.compact
      attr_sender :to_f, *methods, opts
      methods.each { |m| _register_attr(m, :float, opts) }
    end

    alias attr_f attr_float

    def attr_integer_between(min, max, *methods, **opts)
      methods.each do |m|
        attr_type(m, opts, &attr_set(m, opts) { |x| BBLib.keep_between(x, min, max) })
        _register_attr(m, :int_between, opts)
      end
    end

    alias attr_int_between attr_integer_between
    alias attr_i_between attr_integer_between
    alias attr_float_between attr_integer_between
    alias attr_f_between attr_float_between

    def attr_symbol(*methods, **opts)
      methods.each do |m|
        attr_type(m, opts, &attr_set(m, opts) { |x| x.to_s.to_sym })
        _register_attr(m, :symbol, opts)
      end
    end

    alias attr_sym attr_symbol

    def attr_clean_symbol(*methods, **opts)
      methods.each do |m|
        attr_type(m, opts, &attr_set(m, opts) { |x| x.to_s.to_clean_sym })
        _register_attr(m, :clean_symbol, opts)
      end
    end

    alias attr_clean_sym attr_clean_symbol

    def attr_element_of(list, *methods, **opts)
      methods.each do |m|
        attr_type(m, opts, &attr_set(m, opts) do |x|
          unless list.include?(x)
            raise ArgumentError, "#{m} only accepts the following (first 10 shown) #{list[0...10]}; not #{x}."
          else
            instance_variable_set("@#{m}", x)
          end
        end)
        _register_attr(m, :element_of, opts.merge(list: list))
      end
    end

    def attr_array(*methods, **opts)
      methods.each do |m|
        attr_type(m, opts, &attr_set(m, opts) do |x|
          x = [x] unless x.is_a?(Array)
          instance_variable_set("@#{m}", x)
        end)
        attr_array_adder(m, Object, opts) if opts[:adder] || opts[:add_rem]
        attr_array_remover(m, Object, opts) if opts[:remover] || opts[:add_rem]
        _register_attr(m, :array, opts)
      end
    end


    alias attr_ary attr_array

    def attr_array_of(klass, *methods, raise: false, **opts)
      methods.each do |m|
        attr_type(m, opts, &attr_set(m, opts) do |x|
          x = [x] unless x.is_a?(Array)
          x = x.map { |h| attr_serialize(h, *klass) } if opts[:serialize] && !opts[:to_serialize_only]
          if raise && x.any? { |i| klass.is_a?(Array) ? !klass.any? { |k| i.is_a?(k) } : !i.is_a?(klass) }
            raise ArgumentError, "#{m} only accepts items of class #{klass}."
          end
          instance_variable_set("@#{m}", x.reject { |i| klass.is_a?(Array) ? !klass.any? { |k| i.is_a?(k) } : !i.is_a?(klass) })
        end)
        attr_array_adder(m, klass, opts) if opts[:adder] || opts[:add_rem]
        attr_array_remover(m, klass, opts) if opts[:remover] || opts[:add_rem]
        _register_attr(m, :array_of, opts.merge(class: klass))
      end
    end

    alias attr_ary_of attr_array_of

    def attr_array_adder(method, *klasses, **opts)
      define_method(
        (opts[:adder_name] || "add_#{method}"),
        proc do |*args|
          args.each do |arg|
            arg = attr_serialize(arg, *klasses) if opts[:serialize] && !opts[:to_serialize_only]
            if klasses.empty? || klasses.any? { |c| arg.is_a?(c) }
              var = instance_variable_get("@#{method}")
              var = [] if var.nil?
              var.push(arg) unless opts[:uniq] && var.include?(arg)
              instance_variable_set("@#{method}", var)
            elsif opts[:raise]
              raise "Invalid class '#{arg.class}' cannot be added to #{method}. Expected one of the following: #{klasses}"
            end
          end
        end
      )
    end

    def attr_array_remover(method, *_klasses, **opts)
      define_method(
        (opts[:remover_name] || "remove_#{method}"),
        proc do |*args|
          args.map do |arg|
            var = instance_variable_get("@#{method}")
            var = [] if var.nil?
            if arg.is_a?(Integer)
              var.delete_at(arg)
            else
              var.delete(arg)
            end
          end.compact
        end
      )
    end

    def attr_hash(*methods, **opts)
      attr_of(Hash, *methods, **opts)
      methods.each { |m| _register_attr(m, :hash, opts) }
    end

    def attr_json(*methods, **opts)
      attr_of([Hash, Array], *methods, **opts)
      methods.each { |m| _register_attr(m, :json, opts) }
    end

    def attr_valid_file(*methods, raise: true, **opts)
      methods.each do |m|
        attr_type(m, opts, &attr_set(m, opts) { |x| File.exist?(x.to_s) ? x.to_s : (raise ? raise(ArgumentError, "File '#{x}' does not exist. @#{m} must be set to a valid file location!") : nil) })
        _register_attr(m, :valid_file, opts)
      end
    end

    def attr_valid_dir(*methods, raise: true, **opts)
      methods.each do |m|
        attr_type(m, opts, &attr_set(m, opts) { |x| Dir.exist?(x.to_s) ? x.to_s : (raise ? raise(ArgumentError, "Dir '#{x}' does not exist. @#{m} must be set to a valid directory location!") : nil) })
        _register_attr(m, :valid_dir, opts)
      end
    end

    def attr_time(*methods, **opts)
      methods.each do |m|
        attr_type(
          m,
          opts,
          &attr_set(m, opts) do |x|
            if x.is_a?(Time) || x.nil? && opt[:allow_nil]
              x
            elsif x.is_a?(Numeric)
              Time.at(x)
            elsif x.is_a?(String)
              Time.parse(x)
            else
              raise "#{x} is an invalid Time object and could not be converted into a Time object."
            end
          end
        )
        _register_attr(m, :time, opts)
      end
    end

    def attr_set(method, **opts)
      defaults = { allow_nil: false, fallback: :_nil, sender: false, default: nil }
      defaults.each { |k, v| opts[k] = v unless opts.include?(k) }
      proc do |x|
        if opts[:pre_proc]
          [opts[:pre_proc]].flatten.each do |pre_proc|
            x = pre_proc.call(x)
          end
        end
        if x.nil? && !opts[:allow_nil] && opts[:fallback] == :_nil && !opts[:sender]
          raise ArgumentError, "#{method} cannot be set to nil!"
        elsif x.nil? && !opts[:allow_nil] && opts[:fallback] != :_nil && !opts[:sender]
          instance_variable_set("@#{method}", opts[:fallback])
        else
          begin
            instance_variable_set("@#{method}", x.nil? && !opts[:sender] ? x : yield(x))
          rescue StandardError => e
            if opts[:fallback] != :_nil
              instance_variable_set("@#{method}", opts[:fallback])
            else
              raise e
            end
          end
        end
      end
    end
  end
end
