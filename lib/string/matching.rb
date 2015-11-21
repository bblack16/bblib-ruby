##############################################
# String Comparison Algorithms
##############################################

module BBLib

  def self.levenshtein_distance a, b, case_sensitive = false
    if !case_sensitive then a, b = a.downcase, b.downcase end
    costs = (0..b.length).to_a
    (1..a.length).each do |i|
      costs[0], nw = i, i - 1
      (1..b.length).each do |j|
        costs[j], nw = [costs[j] + 1, costs[j-1] + 1, a[i-1] == b[j-1] ? nw : nw + 1].min, costs[j]
      end
    end
    costs[b.length]
  end

  def self.levenshtein_similarity a, b, case_sensitive = false
    distance = BBLib.levenshtein_distance a, b, case_sensitive
    max = [a.length, b.length].max.to_f
    return ((max - distance.to_f) / max) * 100.0
  end

  def self.composition_similarity a, b, case_sensitive = false
    if !case_sensitive then a, b = a.downcase, b.downcase end
    if a.length <= b.length then t = a; a = b; b = t; end
    matches, temp = 0, b
    a.chars.each do |c|
      if temp.chars.include? c
        matches+=1
        temp.sub! c, ''
      end
    end
    (matches / [a.length, b.length].max.to_f )* 100.0
  end

  def self.phrase_similarity a, b, case_sensitive = false
    if !case_sensitive then a, b = a.downcase, b.downcase end
    temp = b.split ' '
    matches = 0
    a.split(' ').each do |w|
      if temp.include? w
        matches+=1
        temp.delete_at temp.find_index w
      end
    end
    (matches.to_f / [a.split(' ').size, b.split(' ').size].max.to_f) * 100.0
  end

  def self.numeric_similarity a, b, case_sensitive = false
    if !case_sensitive then a, b = a.downcase, b.downcase end
    a, b = a.scan(/\d+/), b.scan(/\d+/)
    return 100.0 if a.empty? && b.empty?
    matches = []
    for i in 0..[a.size, b.size].max-1
      matches << 1.0 / ([a[i].to_f, b[i].to_f].max - [a[i].to_f, b[i].to_f].min + 1.0)
    end
    (matches.inject{ |sum, m| sum + m } / matches.size.to_f) * 100.0
  end

  def self.qwerty_similarity a, b
    a, b = a.downcase.strip, b.downcase.strip
    if a.length <= b.length then t = a; a = b; b = t; end
    qwerty = {
      1 => ['1','2','3','4','5','6','7','8','9','0'],
      2 => ['q','w','e','r','t','y','u','i','o','p'],
      3 => ['a','s','d','f','g','h','j','k','l'],
      4 => ['z','x','c','v','b','n','m']
    }
    count, offset = 0, 0
    a.chars.each do |c|
      if b.length <= count
        offset+=10
      else
        ai = qwerty.keys.find{ |f| qwerty[f].include? c }.to_i
        bi = qwerty.keys.find{ |f| qwerty[f].include? b.chars[count] }.to_i
        offset+= (ai - bi).abs
        offset+= (qwerty[ai].index(c) - qwerty[bi].index(b.chars[count])).abs
      end
      count+=1
    end
    offset
  end
end

class String
  def levenshtein_distance str, case_sensitive = false
    BBLib.levenshtein_distance self, str, case_sensitive
  end

  def levenshtein_similarity str, case_sensitive = false
    BBLib.levenshtein_similarity self, str, case_sensitive
  end

  def composition_similarity str, case_sensitive = false
    BBLib.composition_similarity self, str, case_sensitive
  end

  def phrase_similarity str, case_sensitive = false
    BBLib.phrase_similarity self, str, case_sensitive
  end

  def numeric_similarity str, case_sensitive = false
    BBLib.numeric_similarity self, str, case_sensitive
  end

  def qwerty_similarity str
    BBLib.qwerty_similarity self, str
  end
end
