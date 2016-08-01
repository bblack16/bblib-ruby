module BBLib

  module Hooks

    def method_added name
      before_hooks_for(name).each do |hook|
        next if before_hooked_methods[hook] && before_hooked_methods[hook].include?(name)
        add_before_hook(name, hook)
      end
      after_hooks_for(name).each do |hook|
        next if after_hooked_methods[hook] && after_hooked_methods[hook].include?(name)
        add_after_hook(name, hook)
      end
    end

    def before hook, *methods
      methods.each{ |m| before_hooks[hook] = methods }
    end

    def before_hooks
      @before_hooks ||= {}
    end

    def before_hooked_methods
      @before_hooked_methods ||= {}
    end

    def before_hooks_for name
      before_hooks.map{ |n, m| m.include?(name)? n : nil }.reject(&:nil?)
    end

    def add_before_hook method, hook
      before_hooked_methods[hook] = Array.new unless before_hooked_methods[hook]
      before_hooked_methods[hook] += [method]
      original = instance_method(method)
      define_method(method) do |*args, &block|
        method(hook).call
        original.bind(self).call(*args, &block)
      end
    end

    def after hook, *methods
      methods.each{ |m| after_hooks[hook] = methods }
    end

    def after_hooks
      @after_hooks ||= {}
    end

    def after_hooked_methods
      @after_hooked_methods ||= {}
    end

    def after_hooks_for name
      after_hooks.map{ |n, m| m.include?(name) ? n : nil }.reject(&:nil?)
    end

    def add_after_hook method, hook
      after_hooked_methods[hook] = Array.new unless after_hooked_methods[hook]
      after_hooked_methods[hook] += [method]
      original = instance_method(method)

      define_method(method) do |*args, &block|
        rtr = original.bind(self).call(*args, &block)
        method(hook).call
        rtr
      end
    end

  end

end
