

module BBLib
  # Adds type casted attr getters and setters with all kinds of other goodness to ensure
  # classes accept, set and return data the correct way without requiring piles or boiler plate
  # code.
  module Attrs

    def _attrs
      @_attrs ||= _ancestor_attrs
    end

    def _ancestor_attrs
      hash = {}
      ancestors.reverse.each do |ancestor|
        next if ancestor == self
        hash = hash.merge(ancestor._attrs) if ancestor.respond_to?(:_attrs)
      end
      # Need to dup to avoid subclasses modifying parents
      hash.hmap do |k, v|
        v[:options] = v[:options].dup
        [k, v.dup]
      end
    end

    def attr_set(name, opts = {})
      return false unless _attrs[name]
      opts.each do |k, v|
        _attrs[name][:options][k] = v
      end
    end

    # Lists all attr_* getter methods that were created on this class.
    def instance_readers
      _attrs.map { |k, v| [:attr_writer].any? { |t| v[:type] == t } ? nil : k }.compact
    end

    # Lists all attr_* setter methods that were created on this class.
    def instance_writers
      _attrs.keys.map { |m| "#{m}=".to_sym }.select { |m| method_defined?(m) }
    end

    def attr_reader(*args, **opts)
      args.each do |arg|
        _register_attr(arg, :attr_reader)
        serialize_method(arg, opts[:serialize_method], opts[:serialize_opts] || {}) if _attr_serialize?(opts)
      end
      super(*args)
    end

    def attr_writer(*args, **opts)
      args.each { |arg| _register_attr(arg, :attr_writer) }
      super(*args)
    end

    def attr_accessor(*args, **opts)
      args.each do |arg|
        _register_attr(arg, :attr_accessor)
        serialize_method(arg, opts[:serialize_method], opts[:serialize_opts] || {}) if _attr_serialize?(opts)
      end
      super(*args)
    end

    def attr_custom(method, opts = {}, &block)
      called_by = caller_locations(1, 1)[0].label.gsub('block in ', '') rescue :attr_custom
      type      = (called_by =~ /^attr_/ ? called_by.to_sym : (opts[:attr_type] || :custom))
      opts      = opts.dup
      ivar      = "@#{method}".to_sym
      mthd_type = opts[:singleton] ? :define_singleton_method : :define_method

      self.send(mthd_type, "#{method}=") do |args|
        if opts[:pre_proc]
          if opts[:pre_proc].is_a?(Proc)
            args = opts[:pre_proc].call(args)
          else
            args = send(opts[:pre_proc], args)
          end
        end
        instance_variable_set(ivar, yield(args))
      end

      self.send(mthd_type, method) do
        if opts[:getter] && opts[:getter].is_a?(Proc)
          opts[:getter].arity == 0 ? opts[:getter].call : opts[:getter].call(self)
        elsif instance_variable_defined?(ivar) && !(var = instance_variable_get(ivar)).nil?
          var
        elsif opts.include?(:default) || opts.include?(:default_proc)
          default_value =
            if opts[:default].respond_to?(:dup) && BBLib.is_any?(opts[:default], Array, Hash)
              opts[:default].dup rescue opts[:default]
            elsif opts[:default_proc].is_a?(Proc)
              prc = opts[:default_proc]
              prc.arity == 0 ? prc.call : prc.call(self)
            elsif opts[:default_proc].is_a?(Symbol)
              send(opts[:default_proc])
            else
              opts[:default]
            end
          send("#{method}=", default_value)
        end
      end

      if opts[:aliases]
        [opts[:aliases]].flatten.each do |als|
          obj = opts[:singleton] ? self.singleton_class : self
          obj.send(:alias_method, als, method)
          obj.send(:alias_method, "#{als}=", "#{method}=")
        end
      end

      unless opts[:singleton]
        protected method if opts[:protected] || opts[:protected_reader]
        protected "#{method}=".to_sym if opts[:protected] || opts[:protected_writer]
        private method if opts[:private] || opts[:private_reader]
        private "#{method}=".to_sym if opts[:private] || opts[:private_writer]

        serialize_method(method, opts[:serialize_method], (opts[:serialize_opts] || {}).merge(default: opts[:default])) if _attr_serialize?(opts)
        _register_attr(method, type, opts)
      end
    end

    def _attr_serialize?(opts)
      return false unless respond_to?(:serialize_method)
      (opts[:private] || opts[:protected]) && opts[:serialize] ||
      (opts.include?(:serialize) && opts[:serialize]) || !opts.include?(:serialize)
    end

    def attr_of(klasses, *methods, **opts)
      allowed = [klasses].flatten
      methods.each do |method|
        attr_custom(method, opts.merge(_attr_type: :of, classes: klasses)) do |arg|
          if BBLib.is_any?(arg, *allowed) || (arg.nil? && opts[:allow_nil])
            arg
          elsif arg && (!opts.include?(:pack) || opts[:pack]) && arg = _attr_pack(arg, klasses, opts)
            arg
          else
            raise TypeError, "#{method} must be set to a class of #{allowed.join_terms(:or)}, not #{arg.class} (#{self})" unless opts[:suppress]
          end
        end
      end
    end

    def attr_string(*methods, **opts)
      methods.each do |method|
        attr_custom(method, opts) { |arg| arg.nil? && opts[:allow_nil] ? arg : arg.to_s }
      end
    end

    alias attr_str attr_string

    def attr_integer(*methods, **opts)
      methods.each do |method|
        attr_custom(method, opts) { |arg| arg.nil? && opts[:allow_nil] ? arg : arg.to_i }
      end
    end

    alias attr_int attr_integer

    def attr_float(*methods, **opts)
      methods.each do |method|
        attr_custom(method, opts) { |arg| arg.nil? && opts[:allow_nil] ? arg : arg.to_f }
      end
    end

    def attr_symbol(*methods, **opts)
      methods.each do |method|
        attr_custom(method, opts) do |arg|
          if arg.nil?
            opts[:allow_nil] ? arg : raise(ArgumentError, "#{method} cannot be set to nil.")
          else
            arg.to_s.to_sym
          end
        end
      end
    end

    alias attr_sym attr_symbol

    def attr_boolean(*methods, **opts)
      methods.each do |method|
        attr_custom(method, opts) { |arg| arg ? true : false }
        next if opts[:no_?]
        if opts[:singleton]
          singleton_class.send(:alias_method, "#{method}?", method)
        else
          alias_method "#{method}?", method
        end
      end
    end

    alias attr_bool attr_boolean

    def attr_integer_between(min, max, *methods, **opts)
      methods.each do |method|
        attr_custom(method, opts.merge(min: min, max: max)) { |arg| arg.nil? && opts[:allow_nil] ? arg : BBLib.keep_between(arg, min, max).to_i }
      end
    end

    alias attr_int_between attr_integer_between

    def attr_float_between(min, max, *methods, **opts)
      methods.each do |method|
        attr_custom(method, opts.merge(min: min, max: max)) { |arg| arg.nil? && opts[:allow_nil] ? arg : BBLib.keep_between(arg, min, max).to_f }
      end
    end

    def attr_integer_loop(min, max, *methods, **opts)
      methods.each do |method|
        attr_custom(method, opts) { |arg| arg.nil? && opts[:allow_nil] ? arg : BBLib.loop_between(arg, min, max) }
      end
    end

    alias attr_int_loop attr_integer_loop
    alias attr_float_loop attr_integer_loop

    def attr_element_of(list, *methods, **opts)
      methods.each do |method|
        attr_custom(method, opts.merge(list: list)) do |arg|
          ls = list.is_a?(Proc) ? list.call(self) : list
          if ls.include?(arg) || (opts[:allow_nil] && arg.nil?)
            arg
          elsif opts[:fallback]
            opts[:fallback]
          else
            raise ArgumentError, "Invalid option '#{arg}' for #{method}." unless opts.include?(:raise) && !opts[:raise]
          end
        end
      end
    end

    def attr_elements_of(list, *methods, **opts)
      opts[:default] = [] unless opts.include?(:default) || opts.include?(:default_proc)
      methods.each do |method|
        attr_custom(method, opts.merge(list: list)) do |args|
          ls = list.is_a?(Proc) ? list.call(self) : list
          [].tap do |final|
            [args].flatten(1).each do |arg|
              if ls.include?(arg) || (opts[:allow_nil] && arg.nil?)
                final << arg
              else
                raise ArgumentError, "Invalid option '#{arg}' for #{method}." unless opts.include?(:raise) && !opts[:raise]
              end
            end
          end
        end
      end
    end

    def attr_array(*methods, **opts)
      opts[:default] = [] unless opts.include?(:default) || opts.include?(:default_proc)
      methods.each do |method|
        attr_custom(method, opts) do |arg|
          if opts[:allow_nil] && arg.nil?
            arg
          else
            args = arg.is_a?(Array) ? arg : [arg]
            args = args.uniq if opts[:uniq]
            args
          end
        end
        attr_array_adder(method, opts[:adder_name], singleton: opts[:singleton]) if opts[:add_rem] || opts[:adder]
        attr_array_remover(method, opts[:remover_name], singleton: opts[:singleton]) if opts[:add_rem] || opts[:remover]
      end
    end

    alias attr_ary attr_array

    def attr_array_of(klasses, *methods, **opts)
      opts[:default] = [] unless opts.include?(:default) || opts.include?(:default_proc)
      klasses = [klasses].flatten
      methods.each do |method|
        attr_custom(method, opts.merge(classes: klasses)) do |args|
          array = []
          if args.nil?
            if opts[:allow_nil]
              array = nil
            else
              raise ArgumentError, "#{method} cannot be set to nil."
            end
          else
            args = [args] unless args.is_a?(Array)
            args.each do |arg|
              match = BBLib.is_any?(arg, *klasses)
              if match
                array.push(arg)
              elsif arg && (!opts.include?(:pack) || opts[:pack]) && arg = _attr_pack(arg, klasses, opts)
                array.push(arg)
              else
                raise TypeError, "Invalid class passed to #{method} on #{self}: #{arg.class}. Must be a #{klasses.join_terms(:or)}." unless opts[:suppress]
              end
            end
          end
          opts[:uniq] ? array.uniq : array
        end
        attr_array_adder(method, opts[:adder_name], singleton: opts[:singleton]) if opts[:add_rem] || opts[:adder]
        attr_array_remover(method, opts[:remover_name], singleton: opts[:singleton]) if opts[:add_rem] || opts[:remover]
      end
    end

    alias attr_ary_of attr_array_of

    def attr_array_adder(method, name = nil, singleton: false, &block)
      name = "add_#{method}" unless name
      mthd_type = singleton ? :define_singleton_method : :define_method
      send(mthd_type, name) do |*args|
        array = send(method)
        [args].flatten(1).each do |arg|
          arg = yield(arg) if block_given?
          array.push(arg)
        end
        send("#{method}=", array)
      end
    end

    def attr_array_remover(method, name = nil, singleton: false)
      name = "remove_#{method}" unless name
      define_method(name) do |*args|
        array = instance_variable_get("@#{method}")
        [args].flatten(1).map do |arg|
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
            [opts[:formats]].flatten.each do |format|
              arg = Time.strptime(arg, format) rescue arg
            end
          end
          if arg.is_a?(Time) || arg.nil? && opts[:allow_nil]
            arg
          elsif arg.is_a?(Numeric)
            Time.at(arg)
          else
            begin
              Time.parse(arg.to_s)
            rescue => _e
              nil
            end
          end
        end
      end
    end

    def attr_date(*methods, **opts)
      methods.each do |method|
        attr_custom(method, **opts) do |arg|
          if opts[:formats]
            arg = arg.to_s
            [opts[:formats]].flatten.each do |format|
              arg = Date.strptime(arg, format) rescue arg
            end
          end
          if arg.is_a?(Date) || arg.nil? && opts[:allow_nil]
            arg
          elsif arg.is_a?(Numeric)
            Date.parse(Time.at(arg).to_s)
          else
            begin
              Date.parse(arg.to_s)
            rescue => _e
              nil
            end
          end
        end
      end
    end

    def attr_hash(*methods, **opts)
      opts[:default] = {} unless opts.include?(:default) || opts.include?(:default_proc)
      methods.each do |method|
        attr_custom(method, **opts) do |arg|
          raise ArgumentError, "#{method} must be set to a hash, not a #{arg.class} (for #{self})." unless arg.is_a?(Hash) || arg.nil? && opts[:allow_nil]
          if opts[:keys] && arg
            arg.keys.each do |key|
              if BBLib.is_any?(key, *opts[:keys])
                next
              elsif (opts.include?(:pack_key) && opts[:pack_key]) && new_key = _attr_pack(key, klasses, opts)
                arg[new_key] = arg.delete(key)
              else
                raise ArgumentError, "Invalid key type for #{method}: #{key.class}. Must be #{[opts[:keys]].flatten.join_terms(:or)}."
              end
            end
          end
          if opts[:values] && arg
            arg.each do |key, value|
              if BBLib.is_any?(value, *opts[:values])
                next
              elsif (!opts.include?(:pack_value) || opts[:pack_value]) && value = _attr_pack(value, klasses, opts)
                arg[key] = arg.delete(value)
              else
                raise TypeError, "Invalid value type for #{method}: #{value.class}. Must be #{opts[:values].join_terms(:or)}."
              end
            end
          end
          arg = arg.keys_to_sym if opts[:symbol_keys] && arg
          arg
        end
      end
    end

    def _attr_pack(arg, klasses, opts = {}, &block)
      klasses = [klasses].flatten
      unless BBLib.is_any?(arg, *klasses)
        return klasses.first.new(*[arg].flatten(1), &block) if klasses.first.respond_to?(:new)
      end
      nil
    end

    protected

    def _register_attr(method, type, opts = {})
      _attrs[method] = { type: type.to_s.sub(/^attr_/, '').to_sym, options: opts }
      method
    end

  end
end
