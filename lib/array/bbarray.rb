
# frozen_string_literal: true
module BBLib
  # Takes two arrays (can be of different length) and interleaves
  # them like [a[0], b[0], a[1], b[1]...]
  def self.interleave(a, b)
    ary = []
    [a.size, b.size].max.times do |i|
      ary.push(a[i]) if i < a.size
      ary.push(b[i]) if i < b.size
    end
    ary
  end

  def self.most_frequent(*args)
    totals = args.each_with_object(Hash.new(0)) { |v, h| h[v] += 1 }
    max = totals.values.max
    totals.keys.find { |k| totals[k] == max }
  end

  def self.most_frequent_str(*args, case_insensitive: false)
    most_frequent(*args.map { |a| case_insensitive ? a.to_s.downcase : a.to_s })
  end
end

class Array
  def msplit(*delims)
    map { |i| i.msplit(*delims) if i.respond_to?(:msplit) }.flatten
  end
  alias multi_split msplit

  def keys_to_sym(clean: false)
    map { |v| v.respond_to?(:keys_to_sym) ? v.keys_to_sym(clean: clean) : v }
  end

  def keys_to_s
    map { |v| v.respond_to?(:keys_to_s) ? v.keys_to_s : v }
  end

  def interleave(b)
    BBLib.interleave self, b
  end

  def diff(b)
    (self-b) + (b-self)
  end

  def to_tree_hash
    TreeHash.new(self)
  end
end
