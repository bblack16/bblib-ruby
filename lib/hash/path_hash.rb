
# This module provides similar functionality as hash path, but instead
# generates a PathHash object which wraps a Hash or Array. Elements may
# be accessed via method calls rather than path strings.

module BBLib

  def self.path_hash hash
    PathHash.new(hash)
  end

  class PathHash < BasicObject
    attr_reader :hash, :recursive

    def initialize hash
      @hash = hash
    end

    def [] val
      PathHash.new(@hash.map{ |h| h[val]} )
    end

    def _val
      @hash
    end

    alias_method :_v, :_val

    def _fval
      @hash.first rescue @hash
    end

    alias_method :_f, :_fval

    def _
      @recursive = true
      self
    end

    def _path arg, formula = nil
      method_missing arg, formula
    end

    private

    def method_missing arg, formula = nil
      arg = (@recursive ? "..#{arg}" : arg.to_s) +
            (formula ? "(#{formula})" : '')
      if @hash.is_a?(::Array)
        PathHash.new @hash.map{ |h| if h.is_a?(::Array) || h.is_a?(::Hash) then h.hash_path(arg) end }.flatten(1)
      else
        PathHash.new @hash.hpath(arg)
      end
    end

  end

end


class Hash

  def path_hash
    BBLib::path_hash(self)
  end

  alias_method :phash, :path_hash
  alias_method :_ph, :path_hash

end

class Array

  def path_hash
    BBLib::path_hash(self)
  end

  alias_method :phash, :path_hash
  alias_method :_ph, :path_hash

end
