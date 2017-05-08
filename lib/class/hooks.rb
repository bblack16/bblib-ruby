

module BBLib
  # Adds method hooking capability to a class. Intended to be used as a mixin.
  module Hooks

    [:before, :after].each do |hook_type|
      define_method(hook_type) do |*methods, **opts|
        raise ArgumentError, 'You must pass in at least one method followed by the name of the hook method.' if methods.size < 2
        hooks = _hooks[hook_type][methods.pop] ||= { methods: [], opts: {} }
        hooks[:methods] += methods
        hooks[:opts] = hooks[:opts].deep_merge(opts)
        true
      end
    end

    def method_added(method)
      super
      [:before, :after].each do |hook_type|
        _hooks[hook_type].find_all { |hook, data| data[:methods].include?(method) }.to_h.each do |hook, data|
          next if _hooked_methods[hook_type] && _hooked_methods[hook_type][hook] && _hooked_methods[hook_type][hook].include?(method)
          send("_hook_#{hook_type}_method", method, hook, data[:opts])
        end
      end
    end

    def _hooks
      @_hooks ||= { before: {}, after: {} }
    end

    def _hooked_methods
      @_hooked_methods ||= { before: {}, after: {} }
    end

    def _add_hooked_method(type, hook, method)
      history = _hooked_methods[type]
      history[hook] = [] unless history[hook]
      history[hook].push(method)
    end

    # Current opts:
    # send_args - Sends the arguments of the method to the before hook.
    # modify_args - Replaces the original args with the returned value of the
    # send_method - Sends the method name as an argument to the hooked method.
    #               before hook method.
    def _hook_before_method(method, hook, opts = {})
      return false if method == hook
      _add_hooked_method(:before, hook, method)
      original = instance_method(method)
      define_method(method) do |*args, &block|
        if opts[:send_args] || opts[:send_arg] || opts[:modify_args] || opts[:send_method]
          margs = args
          margs = [method] + args if opts[:send_method]
          margs = args + [opts[:add_args]].flatten(1) if opts[:add_args]
          result = method(hook).call(*margs)
          args = result if opts[:modify_args]
        else
          method(hook).call
        end
        original.bind(self).call(*args, &block)
      end
    end

    # Current opts:
    # send_args - Sends the arguments of the method to the after method.
    # send_value - Sends the return value of the method to the hook method.
    # send_value_ary - Sends the return value of the method to the hook method
    # =>                with the splat operator.
    # modify_value - Opts must also include one of the two above. Passes the returned
    # =>              value of the method to the hook and returns the hooks value
    # =>              rather than the original methods value.
    def _hook_after_method(method, hook, opts = {})
      return false if method == hook
      _add_hooked_method(:after, hook, method)
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
end
