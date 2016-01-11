
require_relative 'matching.rb'
require_relative 'roman.rb'
require_relative 'fuzzy_matcher.rb'

module BBLib

  ##############################################
  # General Functions
  ##############################################

  # Quickly remove any symbols from a string leaving onl alpha-numeric characters and white space.
  def self.drop_symbols str
    str.gsub(/[^\w\s\d]|_/, '')
  end

  # Extract all integers from a string. Use extract_floats if numbers may contain decimal places.
  def self.extract_integers str, convert: true
    str.scan(/\d+/).map{ |d| convert ? d.to_i : d }
  end

  # Extracts all integers or decimals from a string into an array.
  def self.extract_floats str, convert: true
    str.scan(/\d+\.?\d+|\d+/).map{ |f| convert ? f.to_f : f }
  end

  # Alias for extract_floats
  def self.extract_numbers str, convert: true
    BBLib.extract_floats str, convert:convert
  end

  # Used to move the position of the articles 'the', 'a' and 'an' in strings for normalization.
  def self.move_articles str, position = :front, capitalize: true
    return str unless [:front, :back, :none].include? position
    articles = ["the", "a", "an"]
    articles.each do |a|
      starts, ends = str.downcase.start_with?(a + ' '), str.downcase.end_with?(' ' + a)
      if starts && position != :front
        if position == :none
          str = str[(a.length + 1)..str.length]
        elsif position == :back
          str = str[(a.length + 1)..str.length] + (!ends ? ", #{capitalize ? a.capitalize : a}" : '')
        end
      end
      if ends && position != :back
        if position == :none
          str = str[0..-(a.length + 2)]
        elsif position == :front
          str = (!starts ? "#{capitalize ? a.capitalize : a} " : '') + str[0..-(a.length + 2)]
        end
      end
    end
    while str.strip.end_with?(',')
      str.strip!
      str.chop!
    end
    str
  end

end

class String
  # Multi-split. Similar to split, but can be passed an array of delimiters to split on.
  def msplit delims, keep_empty: false
    return [self] unless !delims.nil? && !delims.empty?
    ar = [self]
    delims.each do |d|
      ar.map!{ |a| a.split d }
      ar.flatten!
    end
    keep_empty ? ar : ar.reject{ |l| l.empty? }
  end

  def move_articles position, capitalize = true
    BBLib.move_articles self, position, capitalize
  end

  def move_articles! position, capitalize = true
    replace BBLib.move_articles(self, position, capitalize)
  end

  def drop_symbols
    BBLib.drop_symbols self
  end

  def drop_symbols!
    replace BBLib.drop_symbols(self)
  end

  def extract_integers convert: true
    BBLib.extract_integers self, convert:convert
  end

  def extract_numbers convert: true
    BBLib.extract_numbers self, convert:convert
  end
end
