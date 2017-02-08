class TreeHash
  attr_reader :container, :parent, :children

  def initialize(container = {}, parent = nil)
    @children  = {}
    @parent    = parent
    @container = container
    build_from(container)
  end

  def value
    @container
  end

  def root?
    @parent.nil?
  end

  def children?
    @children.is_a?(Hash) && !@children.empty?
  end

  def [](key)
    children[key]
  end

  def []=(key, value)
    add_child(key, value)
    container[key] = value
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

  def paths
    if container.is_a?(Array) || container.is_a?(Hash)
      container.squish.keys
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
    (ancestors[1..-1].map(&:key) + [key]).join('.')
  end

  def inspect
    container
  end

  def to_s
    container.to_s
  end

  def method_missing(*args, &block)
    if container.respond_to?(args.first)
      container.send(*args, &block)
    else
      super
    end
  end

  def respond_to_missing?(method, include_private = false)
    container.respond_to?(method, include_private)
  end

  def siblings
    parent.children.map { |_k, c| c == self ? nil : c }.compact
  end

  def index
    parent.children.values.index(self)
  end

  def key
    return nil if root?
    case parent.container
    when Hash
      parent.keys[index]
    when Array
      index
    else
      nil
    end
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
    root? ? self : parent
  end

  protected

  def build_from(container)
    case container
    when Hash
      container.each { |k, v| @children[k] = TreeHash.new(v, self) }
    when Array
      container.each_with_index { |a, i| @children[i] = TreeHash.new(a, self) }
    else
      @children = container
    end
  end

  def add_child(key, child)
    @children[key] = TreeHash.new(child, self)
  end

end
