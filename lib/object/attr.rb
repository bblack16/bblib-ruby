module BBLib::Attr

  private

  def attr_type method, opts, &block
    define_method("#{method}=", &block)
    define_method(method){ instance_variable_get("@#{method}")}
    if defined?(:before) && opts.include?(:default)
      define_method("__reset_#{method}".to_sym){ send("#{method}=", opts[:default]) }
    end
  end

  def attr_sender call, *methods, **opts
    methods.each do |m|
      attr_type(
        m,
        opts,
        &attr_set(
          m,
          opts.merge(sender: true)
        ){ |x| x.nil? && opts[:allow_nil] ? nil : x.send(call) }
      )
    end
  end

  def attr_of klass, *methods, **opts
    methods.each{ |m| attr_type(m, opts, &attr_set(m, opts){ |x|
        if x.is_a?(klass)
          instance_variable_set("@#{m}", x)
        else
          raise ArgumentError, "#{method} must be set to a #{klass}!"
        end
      }
    )
  }
  end

  def attr_boolean *methods, **opts
    methods.each{ |m|
      attr_type(m, opts) { |x| instance_variable_set("@#{m}", !!x && x.to_s != 'false') }
      alias_method "#{m}?", m unless opts[:no_q]
    }
  end

  alias_method :attr_bool, :attr_boolean

  def attr_string *methods, **opts
    attr_sender :to_s, *methods, opts
  end

  alias_method :attr_str, :attr_string
  alias_method :attr_s, :attr_string

  def attr_integer *methods, **opts
    attr_sender :to_i, *methods, opts
  end

  alias_method :attr_int, :attr_integer
  alias_method :attr_i, :attr_integer

  def attr_float *methods, **opts
    attr_sender :to_f, *methods, opts
  end

  alias_method :attr_f, :attr_float

  def attr_integer_between min, max, *methods, **opts
    methods.each{ |m| attr_type(m, opts, &attr_set(m, opts){ |x| BBLib::keep_between(x, min, max) })}
  end

  alias_method :attr_int_between, :attr_integer_between
  alias_method :attr_i_between, :attr_integer_between
  alias_method :attr_float_between, :attr_integer_between
  alias_method :attr_f_between, :attr_float_between

  def attr_symbol *methods, **opts
    methods.each{ |m| attr_type(m, opts, &attr_set(m, opts){ |x| x.to_s.to_sym } )}
  end

  alias_method :attr_sym, :attr_symbol

  def attr_clean_symbol *methods, **opts
    methods.each{ |m| attr_type(m, opts, &attr_set(m, opts){ |x| x.to_s.to_clean_sym } )}
  end

  alias_method :attr_clean_sym, :attr_clean_symbol

  def attr_array *methods, **opts
    methods.each{ |m| attr_type(m, opts, &attr_set(m, opts){ |*x| instance_variable_set("@#{m}", x) } )}
  end

  alias_method :attr_ary, :attr_array

  def attr_element_of list, *methods, **opts
    methods.each do |m|
      attr_type(m, opts, &attr_set(m, opts) do |x|
          if !list.include?(x)
            raise ArgumentError, "#{m} only accepts the following (first 10 shown) #{list[0...10]}"
          else
            instance_variable_set("@#{m}", x)
          end
        end
      )
    end
  end

  def attr_array_of klass, *methods, raise: false, **opts
    methods.each do |m|
      attr_type(m, opts, &attr_set(m, opts) do |*x|
          if raise && x.any?{ |i| klass.is_a?(Array) ? !klass.any?{ |k| i.is_a?(k) } : !i.is_a?(klass) }
            raise ArgumentError, "#{m} only accepts items of class #{klass}."
          end
          instance_variable_set("@#{m}", x.reject{|i| klass.is_a?(Array) ? !klass.any?{ |k| i.is_a?(k) } : !i.is_a?(klass) })
        end
      )
    end
  end

  alias_method :attr_ary_of, :attr_array_of

  def attr_hash *methods, **opts
    methods.each{ |m| attr_type(m, opts, &attr_set(m, opts) do |*a|
          begin
            hash = a.find_all{ |i| i.is_a?(Hash) }.inject({}){ |m, h| m.merge(h) } || Hash.new
            instance_variable_set("@#{m}", hash)
          rescue ArgumentError => e
            raise ArgumentError, "#{m} only accepts a hash for its parameters"
          end
        end
      )
    }
  end

  def attr_valid_file *methods, raise: true, **opts
    methods.each{ |m| attr_type(m, opts, &attr_set(m, opts){ |x| File.exists?(x.to_s) ? x.to_s : (raise ? raise(ArgumentError, "File '#{x}' does not exist. @#{m} must be set to a valid file location!") : nil)} )}
  end

  def attr_valid_dir *methods, raise: true, **opts
    methods.each{ |m| attr_type(m, opts, &attr_set(m, opts){ |x| Dir.exists?(x.to_s) ? x.to_s : (raise ? raise(ArgumentError, "Dir '#{x}' does not exist. @#{m} must be set to a valid directory location!") : nil)} )}
  end

  def attr_time *methods, **opts
    methods.each do |m|
      attr_type(
        m,
        opts,
        &attr_set(m, opts){ |x|
          if x.is_a?(Time) || x.nil? && opt[:allow_nil]
            x
          elsif x.is_a?(Numeric)
            Time.at(x)
          elsif x.is_a?(String)
            Time.parse(x)
          else
            raise "#{x} is an invalid Time object and could not be converted into a Time object."
          end
        }
      )
    end
  end

  def attr_set method, allow_nil: false, fallback: :_nil, sender: false, default: nil, &block
    proc{ |x|
      if x.nil? && !allow_nil && fallback == :_nil && !sender
        raise ArgumentError, "#{method} cannot be set to nil!"
      elsif x.nil? && !allow_nil && fallback != :_nil && !sender
        instance_variable_set("@#{method}", fallback)
      else
        begin
          instance_variable_set("@#{method}", x.nil? && !sender ? x : yield(x) )
        rescue Exception => e
          if fallback != :_nil
            instance_variable_set("@#{method}", fallback)
          else
            raise e
          end
        end
      end
    }
  end

end
