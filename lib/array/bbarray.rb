# frozen_string_literal: true
module BBLib
  # Takes two arrays (can be of different length) and interleaves
  # them like [a[0], b[0], a[1], b[1]...]
  def self.interleave(ary_a, ary_b)
    ary = []
    [ary_a.size, ary_b.size].max.times do |indx|
      ary.push(ary_a[indx]) if indx < ary_a.size
      ary.push(ary_b[indx]) if indx < ary_b.size
    end
    ary
  end

  # Returns the element that occurs the most frequently in an array or
  def self.most_frequent(*args)
    totals = args.each_with_object(Hash.new(0)) { |elem, hash| hash[elem] += 1 }
    max = totals.values.max
    totals.keys.find { |key| totals[key] == max }
  end

  # Returns the most commonly occurring string in an arrray of params.
  # Elements that are not strings are converted to their string representations.
  #
  # @param [TrueClass, FalseClass] case_insensitive Compare strings case isensitively.
  def self.most_frequent_str(*args, case_insensitive: false)
    most_frequent(*args.map { |arg| case_insensitive ? arg.to_s.downcase : arg.to_s })
  end

  # Takes an array and averages all of the floats and integers within it.
  # Non numeric values are ignored.
  def self.average(ary)
    numbers = ary.select { |v| BBLib.is_a?(v, Integer, Float) }
    numbers.inject(0) do |sum, x|
      sum += x
    end / numbers.size.to_f
  end
end

# Monkey Patches for the Array class
class Array
  # Splits all elements in an array using a list of delimiters.
  def msplit(*delims)
    map { |elem| elem.msplit(*delims) if elem.respond_to?(:msplit) }.flatten
  end

  alias multi_split msplit

  # Converts all keys in nested hashes to symbols.
  def keys_to_sym(clean: false)
    map { |elem| elem.respond_to?(:keys_to_sym) ? elem.keys_to_sym(clean: clean) : elem }
  end

  # Converts all keys in nested hashes to strings.
  def keys_to_s
    map { |v| v.respond_to?(:keys_to_s) ? v.keys_to_s : v }
  end

  # Takes two arrays (can be of different length) and interleaves
  # them like [a[0], b[0], a[1], b[1]...]
  def interleave(ary)
    BBLib.interleave(self, ary)
  end

  # Displays all elements between this hash and another hash that are different.
  # @param [Array] ary The ary to compare elements to.
  def diff(ary)
    (self - ary) + (ary - self)
  end

  # Creates a tree hash wrapper for this array.
  def to_tree_hash
    TreeHash.new(self)
  end

  # Conventient way to join an array into a comma seperated list with the last two elements
  # seperated by a word like 'and' or 'or'.
  # @param seperator [String] The term or phrase to seperate the last two elements by
  # @param delimiter [String] The delimiter used in the join. This allows something other than ', ' to be used
  # @param encapsulate [String] This will optionally encapsulate each element with a character or string. Useful to wrap all elements in quotes.
  # @returns [String] By default returns a comma seperated list with the final elements seperated by an 'and'. Behavior can be overriden using the params.
  def join_terms(seperator = :and, delimiter: ', ', encapsulate: nil)
    elements = (encapsulate ? map { |element| element.to_s.encapsulate(encapsulate) } : self)
    return elements.join(delimiter) if size <= 1
    return elements.join(" #{seperator} ") if size == 2
    [elements[0..-2].join(delimiter), elements.last].join(" #{seperator} ")
  end
end
