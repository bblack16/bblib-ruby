# frozen_string_literal: true
require_relative 'part'
require_relative 'proc'
require_relative 'path_hash'

# This classes parses dot delimited hash path strings and wraps the corresponding parts. Then hashes or arrays can be
# passed to the find method to find all matching elements for the path.
class HashPath
  include BBLib::Effortless
  attr_ary_of Part, :parts, default: []

  def append(path)
    insert(path, parts.size)
  end

  def prepend(path)
    insert(path, 0)
  end

  def insert(path, index)
    parse_path(path).each do |part|
      parts[index] = part
      index += 1
    end
  end

  def find(hash)
    hash = TreeHash.new unless hash.is_a?(TreeHash)
    hash.find(self)
  end

  protected

  def simple_init(*args)
    args.find_all { |arg| arg.is_a?(String) || arg.is_a?(Symbol) }.each do |path|
      append(path.to_s)
    end
  end

  def parse_path(path)
    path.to_s.gsub('..', '.[[:recursive:]]').scan(/(?:[\(|\[|\/].*?[\)|\]|\/]|\\\.|[^\.])+/).map do |part|
      Part.new(part)
    end
  end
end

module BBLib
  def self.hash_path(hash, *paths, multi_path: false, multi_join: false, multi_join_hash: false)
    tree = TreeHash.new(hash)
    if multi_path
      tree.find_multi(*paths).map  { |r| r.map { |sr| sr.value } }
    elsif multi_join
      tree.find_join(*paths).map { |r| r.map { |sr| sr.value } }
    elsif multi_join_hash
      tree.find_join(*paths).map { |r| r.map { |sr| sr.value } }.to_h
    else
      tree.find(paths).map(&:value)
    end
  end

  def self.hash_path_keys(hash)
    hash.to_tree_hash.absolute_paths
  end

  def self.hash_path_key_for(hash, value)
    hash.squish.find_all { |_k, v| value.is_a?(Regexp) ? v =~ value : v == value }.to_h.keys
  end

  def self.hash_path_set(hash, *paths)
    tree = hash.is_a?(TreeHash) ? hash : TreeHash.new(hash)
    tree.bridge(*paths)
    hash.replace(tree.value)
  end

  def self.hash_path_copy(hash, *paths)
    tree = hash.is_a?(TreeHash) ? hash : TreeHash.new(hash)
    tree.copy(*paths)
    hash.replace(tree.value)
  end

  def self.hash_path_copy_to(from, to, *paths)
    tree = from.is_a?(TreeHash) ? from : TreeHash.new(from)
    tree.hash_path_copy_to(to, *paths)
  end

  def self.hash_path_delete(hash, *paths)
    tree = hash.is_a?(TreeHash) ? hash : TreeHash.new(hash)
    tree.delete(*paths)
    hash.replace(tree.value)
  end

  def self.hash_path_move(hash, *paths)
    tree = hash.is_a?(TreeHash) ? hash : TreeHash.new(hash)
    tree.move(*paths)
    hash.replace(tree.value)
  end

  def self.hash_path_move_to(from, to, *paths)
    tree = hash.is_a?(TreeHash) ? hash : TreeHash.new(hash)
    tree.hash_path_copy_to(to, *paths).tap do |res|
      from.replace(tree.value)
      to.replace(res.value)
    end
    to
  end

end

# Monkey patches
class Hash
  def hash_path(*path)
    BBLib.hash_path self, *path
  end

  def hash_path_set(*paths)
    BBLib.hash_path_set self, *paths
  end

  def hash_path_copy(*paths)
    BBLib.hash_path_copy self, *paths
  end

  def hash_path_copy_to(to, *paths)
    BBLib.hash_path_copy_to self, to, *paths
  end

  def hash_path_delete(*paths)
    BBLib.hash_path_delete self, *paths
  end

  def hash_path_move(*paths)
    BBLib.hash_path_move self, *paths
  end

  def hash_path_move_to(to, *paths)
    BBLib.hash_path_move_to self, to, *paths
  end

  def hash_paths
    BBLib.hash_path_keys self
  end

  def hash_path_for(value)
    BBLib.hash_path_key_for self, value
  end

  alias hpath hash_path
  alias hpath_set hash_path_set
  alias hpath_move hash_path_move
  alias hpath_move_to hash_path_move_to
  alias hpath_delete hash_path_delete
  alias hpath_copy hash_path_copy
  alias hpath_copy_to hash_path_copy_to
  alias hpaths hash_paths
  alias hpath_for hash_path_for
end

# Monkey Patches
class Array
  def hash_path(*path)
    BBLib.hash_path(self, *path)
  end

  def hash_path_set(*paths)
    BBLib.hash_path_set(self, *paths)
  end

  def hash_path_copy(*paths)
    BBLib.hash_path_copy(self, *paths)
  end

  def hash_path_copy_to(to, *paths)
    BBLib.hash_path_copy_to(self, to, *paths)
  end

  def hash_path_delete(*paths)
    BBLib.hash_path_delete(self, *paths)
  end

  def hash_path_move(*paths)
    BBLib.hash_path_move(self, *paths)
  end

  def hash_path_move_to(to, *paths)
    BBLib.hash_path_move_to(self, to, *paths)
  end

  def hash_paths
    BBLib.hash_path_keys(self)
  end

  def hash_path_for(value)
    BBLib.hash_path_key_for(self, value)
  end

  alias hpath hash_path
  alias hpath_set hash_path_set
  alias hpath_move hash_path_move
  alias hpath_move_to hash_path_move_to
  alias hpath_delete hash_path_delete
  alias hpath_copy hash_path_copy
  alias hpath_copy_to hash_path_copy_to
  alias hpaths hash_paths
  alias hpath_for hash_path_for

  # Add a hash path to a hash
  def bridge(*paths)
    replace(to_tree_hash.bridge(*paths))
  end
end
