# frozen_string_literal: true
require_relative 'hash_path_processors'

module BBLib
  class HashPathProc < BBLib::LazyClass
    attr_ary_of String, :paths, default: [''], serialize: true, uniq: true
    attr_of [String, Symbol], :action, default: nil, allow_nil: true, serialize: true, pre_proc: proc { |arg| HashPathProc.map_action(arg.to_sym) }
    attr_ary :args, default: [], serialize: true
    attr_hash :options, default: {}, serialize: true
    attr_of [String, Proc], :condition, default: nil, allow_nil: true, serialize: true
    attr_bool :recursive, default: false, serialize: true
    attr_bool :class_based, default: true, serialize: true

    def process(hash)
      return hash unless @action && hash
      tree = hash.to_tree_hash
      paths.each do |path|
        children = recursive ? tree.find(path).flat_map(&:descendants) : tree.find(path)
        children.each do |child|
          next unless check_condition(child.value)
          HashPathProcs.send(find_action(action), child, *full_args, class_based: class_based)
        end
      end
      hash.replace(tree.value) rescue tree.value
    end

    def check_condition(value)
      return true unless condition
      if condition.is_a?(String)
        eval(condition)
      else
        condition.call(value)
      end
    rescue => e
      false
    end

    protected

    USED_KEYWORDS = [:action, :args, :paths, :recursive, :condition]

    def find_action(action)
      (HashPathProcs.respond_to?(action) ? action : :custom)
    end

    def full_args
      (HASH_PATH_PROC_TYPES.include?(action) ? [] : [action]) +
      args +
      (options.empty? || options.nil? ? [] : [options])
    end

    def self.map_action(action)
      clean = HASH_PATH_PROC_TYPES.find { |k, v| action == k || v.include?(action) }
      clean ? clean.first : action
    end

    def lazy_init(*args)
      options = BBLib.named_args(*args)
      options.merge(options.delete(:options)) if options[:options]
      USED_KEYWORDS.each { |k| options.delete(k) }
      self.options = options
      if args.first.is_a?(Symbol) && @action.nil?
        self.action = args.shift
        self.paths = args.shift if args.first.is_a?(String)
      elsif action && args.first.is_a?(String)
        self.paths = args.first
      end
      self.args += args.find_all { |a| !a.is_a?(Hash) } unless args.empty?
    end
  end
end

class Hash
  def hash_path_proc(*args)
    BBLib::HashPathProc.new(*args).process(self)
  end

  alias hpath_proc hash_path_proc
end

class Array
  def hash_path_proc(*args)
    BBLib::HashPathProc.new(*args).process(self)
  end

  alias hpath_proc hash_path_proc
end
