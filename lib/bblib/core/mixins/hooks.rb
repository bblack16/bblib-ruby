

module BBLib
  # Adds method hooking capability to a class. Intended to be used as a mixin.
  module Hooks

    [:before, :after].each do |hook_type|
      define_method(hook_type) do |*methods, **opts, &block|
        raise ArgumentError, 'You must pass in at least one method followed by the name of the hook method or a block.' if methods.size < 2 && block.nil?
        hooks = _hooks[hook_type][methods.last] ||= { methods: methods[0..-2], opts: { block: block } }
        hooks[:opts] = hooks[:opts].deep_merge(opts)
        methods[0..(block ? -1 : -2)].each { |method| _hook_method(method) if method_defined?(method) }
        true
      end
    end

    def method_added(method)
      if _defining_hook?
        @_defining_hook = false
      else
        _hook_method(method)
      end
    end

    def singleton_method_added(method)
      if _defining_hook?
        @_defining_hook = false
      else
        self.singleton_class.send(:_hook_method, method, force: true) if self.singleton_class.respond_to?(:_hook_method)
      end
    end

    def _hook_method(method, force: false)
      return false if _defining_hook?
      [:before, :after].each do |hook_type|
        _hooks[hook_type].find_all { |hook, data| data[:methods].include?(method) || data[:opts][:block] && hook == method }.to_h.each do |hook, data|
          hook = data[:opts][:block] if data[:opts][:block]
          next if !force && _hooked_methods[hook_type] && _hooked_methods[hook_type][hook.is_a?(Proc) ? hook.object_id : hook] && _hooked_methods[hook_type][hook.is_a?(Proc) ? hook.object_id : hook].include?(method)
          send("_hook_#{hook_type}_method", method, hook, data[:opts])
        end
      end
    end

    # def _hook_all
    #   _hooks.each do |type, hooks|
    #     hooks.each do |hook, data|
    #       data[:methods].each do |method|
    #         _hook_method(method)
    #       end
    #     end
    #   end
    # end

    def _superclass_hooks
      hooks = { before: {}, after: {} }
      ancestors.reverse.each do |ancestor|
        next if ancestor == self
        hooks = hooks.deep_merge(ancestor.send(:_hooks)) if ancestor.respond_to?(:_hooks)
      end
      hooks
    end

    def _hooks
      @_hooks ||= _superclass_hooks
    end

    def _hooked_methods
      @_hooked_methods ||= { before: {}, after: {} }
    end

    def _add_hooked_method(type, hook, method)
      hook = hook.object_id if hook.is_a?(Proc)
      history = _hooked_methods[type]
      history[hook] = {} unless history[hook]
      history[hook][method] = instance_method(method)
    end

    def _defining_hook?
      @_defining_hook ||= false
    end

    # Current opts:
    # send_args - Sends the arguments of the method to the before hook.
    # modify_args - Replaces the original args with the returned value of the
    # send_method - Sends the method name as an argument to the hooked method.
    #               before hook method.
    # try_first   - Sends the args to the desired hook first and if the result
    #               is non-nil, the result is sent instead of calling the hooked
    #               method.
    def _hook_before_method(method, hook, opts = {})
      return false if method == hook
      _add_hooked_method(:before, hook, method)
      original = instance_method(method)
      @_defining_hook = true
      define_method(method) do |*args, &block|
        if opts[:send_args] || opts[:send_arg] || opts[:modify_args] || opts[:send_method] || opts[:try_first]
          margs = args
          margs = [method] + args if opts[:send_method]
          margs = args + [opts[:add_args]].flatten(1) if opts[:add_args]
          result = (hook.is_a?(Proc) ? hook : method(hook)).call(*margs)
          return result if result && opts[:try_first]
          args = result if opts[:modify_args]
        else
          hook.is_a?(Proc) ? hook.call : method(hook).call
        end
        original.bind(self).call(*args, &block)
      end
      @_defining_hook = false
      true
    end

    # Current opts:
    # send_args - Sends the arguments of the method to the after method.
    # send_value - Sends the return value of the method to the hook method.
    # send_value_ary - Sends the return value of the method to the hook method
    # =>                with the splat operator.
    # modify_value - Opts must also include one of the two above. Passes the returned
    # =>              value of the method to the hook and returns the hooks value
    # =>              rather than the original methods value.
    # send_all     - Sends a hash containing the args, method and value (return).
    def _hook_after_method(method, hook, opts = {})
      return false if method == hook
      _add_hooked_method(:after, hook, method)
      original = instance_method(method)
      @_defining_hook = true
      define_method(method) do |*args, &block|
        rtr = original.bind(self).call(*args, &block)
        if opts[:send_args]
          (hook.is_a?(Proc) ? hook : method(hook)).call(*args)
        elsif opts[:send_return] || opts[:send_value]
          result = (hook.is_a?(Proc) ? hook : method(hook)).call(rtr)
          rtr = result if opts[:modify_value] || opts[:modify_return]
        elsif opts[:send_return_ary] || opts[:send_value_ary]
          result = (hook.is_a?(Proc) ? hook : method(hook)).call(*rtr)
          rtr = result if opts[:modify_value] || opts[:modify_return]
        elsif opts[:send_all]
          result = (hook.is_a?(Proc) ? hook : method(hook)).call(args: args, value: rtr, method: method)
        else
          (hook.is_a?(Proc) ? hook : method(hook)).call
        end
        rtr
      end
      @_defining_hook = false
      true
    end
  end
end
