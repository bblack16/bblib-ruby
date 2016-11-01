# frozen_string_literal: true
##############################################
# String Comparison Algorithms
##############################################

module BBLib
  # A simple rendition of the levenshtein distance algorithm
  def self.levenshtein_distance(a, b)
    costs = (0..b.length).to_a
    (1..a.length).each do |i|
      costs[0] = i
      nw = i - 1
      (1..b.length).each do |j|
        costs[j], nw = [costs[j] + 1, costs[j-1] + 1, a[i-1] == b[j-1] ? nw : nw + 1].min, costs[j]
      end
    end
    costs[b.length]
  end

  # Calculates a percentage based match using the levenshtein distance algorithm
  def self.levenshtein_similarity(a, b)
    distance = BBLib.levenshtein_distance a, b
    max = [a.length, b.length].max.to_f
    ((max - distance.to_f) / max) * 100.0
  end

  # Calculates a percentage based match of two strings based on their character composition.
  def self.composition_similarity(a, b)
    if a.length <= b.length
      t = a
      a = b
      b = t
    end
    matches = 0
    temp = b.dup
    a.chars.each do |c|
      if temp.chars.include? c
        matches+=1
        temp = temp.sub(c, '')
      end
    end
    (matches / [a.length, b.length].max.to_f)* 100.0
  end

  # Calculates a percentage based match between two strings based on the similarity of word matches.
  def self.phrase_similarity(a, b)
    temp = b.drop_symbols.split ' '
    matches = 0
    a.drop_symbols.split(' ').each do |w|
      if temp.include? w
        matches+=1
        temp.delete_at temp.find_index w
      end
    end
    (matches.to_f / [a.split(' ').size, b.split(' ').size].max.to_f) * 100.0
  end

  # Extracts all numbers from two strings and compares them and generates a percentage of match.
  # Percentage calculations here need to be weighted better...TODO
  def self.numeric_similarity(a, b)
    a = a.extract_numbers
    b = b.extract_numbers
    return 100.0 if a.empty? && b.empty? || a == b
    matches = []
    for i in 0..[a.size, b.size].max-1
      matches << 1.0 / ([a[i].to_f, b[i].to_f].max - [a[i].to_f, b[i].to_f].min + 1.0)
    end
    (matches.inject { |sum, m| sum + m } / matches.size.to_f) * 100.0
  end

  # A simple character distance calculator that uses qwerty key positions to determine how similar two strings are.
  # May be useful for typo detection.
  def self.qwerty_distance(a, b)
    a = a.downcase.strip
    b = b.downcase.strip
    if a.length <= b.length
      t = a
      a = b
      b = t
    end
    qwerty = {
      1 => %w(1 2 3 4 5 6 7 8 9 0),
      2 => %w(q w e r t y u i o p),
      3 => %w(a s d f g h j k l),
      4 => %w(z x c v b n m)
    }
    count = 0
    offset = 0
    a.chars.each do |c|
      if b.length <= count
        offset+=10
      else
        ai = qwerty.keys.find { |f| qwerty[f].include? c }.to_i
        bi = qwerty.keys.find { |f| qwerty[f].include? b.chars[count] }.to_i
        offset+= (ai - bi).abs
        offset+= (qwerty[ai].index(c) - qwerty[bi].index(b.chars[count])).abs
      end
      count+=1
    end
    offset
  end
end

class String
  def levenshtein_distance(str)
    BBLib.levenshtein_distance self, str
  end

  def levenshtein_similarity(str)
    BBLib.levenshtein_similarity self, str
  end

  def composition_similarity(str)
    BBLib.composition_similarity self, str
  end

  def phrase_similarity(str)
    BBLib.phrase_similarity self, str
  end

  def numeric_similarity(str)
    BBLib.numeric_similarity self, str
  end

  def qwerty_distance(str)
    BBLib.qwerty_distance self, str
  end
end
