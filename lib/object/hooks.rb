module BBLib::Hooks

  def method_added name
    [:before, :after].each do |hook_type|
      self.send("#{hook_type}_hooks_for", name).each do |hook|
        existing = self.send("#{hook_type}_hooked_methods")[hook[:method]]
        next if existing && existing.include?(name)
        self.send("add_#{hook_type}_hook", name, hook[:method], hook[:opts] || Hash.new)
      end
    end
  end

  def before hook, *methods, **opts
    methods.each{ |m| before_hooks[hook] = { methods: methods, opts: opts } }
  end

  def before_hooks
    @before_hooks ||= {}
  end

  def before_hooked_methods
    @before_hooked_methods ||= {}
  end

  def before_hooks_for name
    before_hooks.map{ |n, m| m[:methods].include?(name)? { method: n, opts: m[:opts] } : nil }.compact
  end

  # Current opts:
  # send_args - Sends the arguments of the method to the before hook.
  # modify_args - Replaces the original args with the returned value of the
  # =>              before hook method.
  def add_before_hook method, hook, opts = Hash.new
    before_hooked_methods[hook] = Array.new unless before_hooked_methods[hook]
    before_hooked_methods[hook] += [method]
    original = instance_method(method)
    define_method(method) do |*args, &block|
      if opts[:send_args] || opts[:send_arg] || opts[:modify_args]
        result = method(hook).call(*args)
        args = result if opts[:modify_args]
      else
        method(hook).call
      end
      original.bind(self).call(*args, &block)
    end
  end

  def after hook, *methods, **opts
    methods.each{ |m| after_hooks[hook] = { methods: methods, opts: opts } }
  end

  def after_hooks
    @after_hooks ||= {}
  end

  def after_hooked_methods
    @after_hooked_methods ||= {}
  end

  def after_hooks_for name
    after_hooks.map{ |n, m| m[:methods].include?(name)? { method: n, opts: m[:opts] } : nil }.compact
  end

  # Current opts:
  # send_args - Sends the arguments of the method to the after method.
  # send_value - Sends the return value of the method to the hook method.
  # send_value_ary - Sends the return value of the method to the hook method
  # =>                with the splat operator.
  # modify_value - Opts must also include one of the two above. Passes the returned
  # =>              value of the method to the hook and returns the hooks value
  # =>              rather than the original methods value.
  def add_after_hook method, hook, opts = Hash.new
    after_hooked_methods[hook] = Array.new unless after_hooked_methods[hook]
    after_hooked_methods[hook] += [method]
    original = instance_method(method)

    define_method(method) do |*args, &block|
      rtr = original.bind(self).call(*args, &block)
      if opts[:send_args]
        method(hook).call(*args)
      elsif opts[:send_return] || opts[:send_value]
        result = method(hook).call(rtr)
        rtr = result if opts[:modify_value] || opts[:modify_return]
      elsif opts[:send_return_ary] || opts[:send_value_ary]
        result = method(hook).call(*rtr)
        rtr = result if opts[:modify_value] || opts[:modify_return]
      else
        method(hook).call
      end
      rtr
    end
  end

end
