
# frozen_string_literal: true
module BBLib
  ROMAN_NUMERALS = { 1000 => 'M', 900 => 'CM', 500 => 'D', 400 => 'CD', 100 => 'C', 90 => 'XC', 50 => 'L',
                     40 => 'XL', 10 => 'X', 9 => 'IX', 5 => 'V', 4 => 'IV', 3 => 'III', 2 => 'II', 1 => 'I' }.freeze
  # Converts any integer up to 1000 to a roman numeral
  def self.to_roman(num)
    return num.to_s if num > 1000
    numeral = ''
    ROMAN_NUMERALS.each do |n, r|
      while num >= n
        num -= n
        numeral += r
      end
    end
    numeral
  end

  def self.string_to_roman(str)
    sp = str.split ' '
    sp.map do |s|
      if s.drop_symbols.to_i.to_s == s.drop_symbols && !(s =~ /\d+\.\d+/)
        s.sub(s.scan(/\d+/).first.to_s, BBLib.to_roman(s.to_i))
      else
        s
      end
    end.join(' ')
  end

  def self.from_roman(str)
    sp = str.split(' ')
    (0..1000).each do |n|
      num = BBLib.to_roman n
      next if sp.select { |i| i[/#{num}/i] }.empty?
      (0..(sp.length-1)).each do |i|
        sp[i] = sp[i].sub(num, n.to_s) if sp[i].drop_symbols.upcase == num
      end
    end
    sp.join ' '
  end
end

class Integer
  def to_roman
    BBLib.to_roman to_i
  end
end

class String
  def from_roman
    BBLib.from_roman self
  end

  def to_roman
    BBLib.string_to_roman self
  end
end
