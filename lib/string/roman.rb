
module BBLib

  # Converts any integer up to 1000 to a roman numeral string_a
  def self.to_roman num
     roman = {1000 => 'M', 900 => 'CM', 500 => 'D', 400 => 'CD', 100 => 'C', 90 => 'XC', 50 => 'L',
              40 => 'XL', 10 => 'X', 9 => 'IX', 5 => 'V', 4 => 'IV', 3 => 'III', 2 => 'II', 1 => 'I'}
    numeral = ""
    roman.each do |n, r|
      if num >= n
        num-= n
        numeral+= r
      end
    end
    numeral
  end

  def self.string_to_roman str
    sp = str.split ' '
    sp.map! do |s|
      if s.to_i.to_s == s
        BBLib.to_roman s.to_i
      else
        s
      end
    end
    sp.join ' '
  end


  def self.from_roman str
    sp = str.split(' ')
    (0..1000).each do |n|
      num = BBLib.to_roman n
      if !sp.select{ |i| i[/#{num}/i]}.empty?
        for i in 0..(sp.length-1)
          if sp[i].upcase == num
            sp[i] = n.to_s
          end
        end
      end
    end
    sp.join ' '
  end

end

class Numeric
  def to_roman
    BBLib.to_roman self.to_i
  end
end

class String
  def from_roman
    BBLib.from_roman self
  end

  def from_roman!
    replace self.from_roman
  end

  def to_roman
    BBLib.string_to_roman self
  end

  def to_roman!
    replace self.to_roman
  end
end
