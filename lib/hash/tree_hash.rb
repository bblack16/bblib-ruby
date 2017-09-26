class TreeHash
  attr_reader :node_class, :parent, :children

  def initialize(object = {}, parent = nil)
    @children = {}
    @parent   = parent
    object    = object.value if object.is_a?(TreeHash)
    replace_with(object)
  end

  def replace_with(object)
    @node_class = object.class
    build_from(object)
  end

  def root?
    @parent.nil?
  end

  def child?
    !root?
  end

  def child(key, symbol_sensitive = false)
    case [node_class]
    when [Hash]
      children[key] || (symbol_sensitive ? nil : children[key.to_s.to_sym])
    when [Array]
      children[key.to_i]
    else
      nil
    end
  end

  def child_exists?(key, symbol_sensitive = false)
    !case [node_class]
    when [Hash]
      children[key] || (!symbol_sensitive && children[key.to_s.to_sym])
    when [Array]
      [0...children.size] === key.to_i
    else
      false
    end.nil?
  end

  def children?
    (node_class == Hash || node_class == Array) && !children.empty?
  end

  def descendants
    return [] unless children?
    desc = []
    children.each do |key, child|
      desc << child
      desc += child.descendants if child.children?
    end
    desc
  end

  def [](key)
    children[key]
  end

  def []=(key, value)
    add_child(key, value)
  end

  def find(path)
    path = HashPath.new(*path) unless path.is_a?(HashPath)
    matches = [self]
    path.parts.each do |part|
      break if matches.empty?
      matches = matches.flat_map do |match|
        part.matches(match)
      end
    end
    matches
  end

  def find_multi(*paths)
    paths.map do |path|
      find(path)
    end
  end

  def find_join(*paths)
    results = find_multi(*paths)
    (0..(results.max_by(&:size).size - 1)).map do |index|
      results.map do |result|
        result[index]
      end
    end
  end

  def find_join_hash(key_path, val_path)
    find_join(key_path, val_path).to_h
  end

  def set(paths)
    paths.each do |path, value|
      find(path).each { |child| child.replace_with(value) }
    end
    self
  end

  # Generate a path using a dot (.) delimited path
  # e.g. bridge('cats.jackson' => :my_value)
  # This modifies the underlying container in place
  def bridge(paths)
    paths = paths.map { |a| [a, nil] }.to_h if paths.is_a?(Array)
    paths.each do |path, value|
      parts     = path.to_s.split(/(?<=[^\\])\./)
      node      = self
      next_part = false
      until next_part.nil?
        part      = next_part || process_bridge_part(parts.shift)
        next_part = process_bridge_part(parts.shift)
        if node.child_exists?(part)
          if next_part.is_a?(Integer)
            next_next = process_bridge_part(parts.first)
            if next_next.is_a?(Integer)
              node[part][next_part] = [] unless node[part][next_part] && node[part][next_part].node_class == Array
            else
              node[part][next_part] = {} unless node[part][next_part] && node[part][next_part].node_class == Hash
            end
          end
          next_part.nil? ? node[part] = value : node = node.child(part)
        else
          if next_part.nil?
            node[part] = value
          else
            node[part] = next_part.is_a?(Integer) ? Array.new(next_part) : {}
          end
          node[part][next_part] = process_bridge_part(parts.first).is_a?(Integer) ? [] : {} if next_part.is_a?(Integer)
          node = node[part]
        end
      end
    end
    self
  end

  def copy(paths)
    paths.each do |from, to|
      value = find(from).first
      bridge(to => value)
    end
    self
  end

  def copy_all(paths)
    paths.each do |from, to|
      value = find(from)
      bridge(to => value)
    end
    self
  end

  def move(paths)
    paths.each do |from, to|
      value = find(from).first
      bridge(to => value)
      value.kill if value
    end
    self
  end

  def move_all(paths)
    paths.each do |from, to|
      value = find(from)
      bridge(to => value)
      value.map(&:kill)
    end
    self
  end

  def copy_to(hash, *paths)
    hash = TreeHash.new(hash) unless hash.is_a?(TreeHash)
    paths.each do |path|
      hash.bridge(path => find(path).first)
    end
    hash
  end

  def move_to(hash, *paths)
    hash = TreeHash.new(hash) unless hash.is_a?(TreeHash)
    paths.each do |path|
      value = find(path).first
      hash.bridge(path => value)
      value.kill if value
    end
    hash
  end

  def to_tree_hash
    self
  end

  def process(processor)

  end

  def size
    @children.respond_to?(:size) ? @children.size : 1
  end

  def paths
    case [node_class]
    when [Array], [Hash]
      value.squish.keys
    else
      []
    end
  end

  def ancestors
    return [] if root?
    return [parent] if parent.root?
    parent.ancestors + [parent]
  end

  def absolute_path
    anc = ancestors[1..-1]
    (anc.nil? ? [] : anc.map(&:path) + [path]).join('.')
  end

  def inspect
    value
  end

  def to_s
    value.to_s
  end

  def siblings
    parent.children.values.map { |c| c == self ? nil : c }.compact
  end

  def index
    parent.children.values.index(self)
  end

  def delete(*paths)
    paths.flat_map do |path|
      find(path).map do |child|
        if child.root?
          delete_child(path)
        else
          child.parent.delete_child(child.key)
        end
      end
    end
  end

  def kill
    root.delete(absolute_path)
  end

  def value
    case [node_class]
    when [Hash]
      children.map { |k, v| [k, v.value] }.to_h
    when [Array]
      children.values.map(&:value)
    else
      children
    end
  end

  def key
    return nil if root?
    case [parent.node_class]
    when [Hash]
      parent.keys[index]
    when [Array]
      index
    else
      nil
    end
  end

  def path
    parent.node_class == Array ? "[#{key}]" : key
  end

  def absolute_paths
    root.paths
  end

  def leaf_children
    return self unless children?
    children.map do |k, v|
      v.children? ? v.leaf_children : v
    end.flatten
  end

  def keys
    return [] unless @children.respond_to?(:keys)
    @children.keys
  end

  def following_siblings(limit = 0)
    siblings[(index + 1)..-(limit.to_i + 1)]
  end

  def preceeding_siblings(limit = 0)
    limit = limit.to_i
    siblings[(limit.zero? ? limit : (index - limit))..(index - 1)]
  end

  def sibling(offset)
    siblings[index + offset.to_i]
  end

  def next_sibling
    sibling(1)
  end

  def previous_sibling
    sibling(-1)
  end

  def root
    return self if root?
    ancestors.find(&:root?)
  end

  def delete_child(key, symbol_sensitive = false)
    case [node_class]
    when [Hash]
      child = symbol_sensitive ? nil : children.delete(key.to_s.to_sym)
      child = children.delete(key) unless child
    when [Array]
      children.delete(key.to_i)
    else
      nil
    end
  end

  protected

  def build_from(object)
    @children = {}
    case object
    when Hash
      object.each { |k, v| @children[k] = TreeHash.new(v, self) }
    when Array
      object.each_with_index { |a, i| @children[i] = TreeHash.new(a, self) }
    else
      @children = object
    end
  end

  def add_child(key, child)
    @children[key] = TreeHash.new(child, self)
  end

  def process_bridge_part(part)
    return unless part
    part =~ /^\[\d+\]$/ ? part.uncapsulate('[').to_i : part.to_sym
  end

end
