
require_relative 'matching.rb'
require_relative 'roman.rb'

module BBLib

  ##############################################
  # General Functions
  ##############################################

  def self.drop_symbols str
    str.gsub(/[^\w\s]/, '')
  end

  def self.extract_numbers str
    str.scan(/\d+/)
  end

  def multi_split str, delims, keep_empty = false
    spl = str.split(/[#{delims.join(',')}]/)
    keep_empty ? spl : spl.reject{ |l| l.empty? }
  end

  def self.move_articles str, position = :front, capitalize = true
    return str unless position == :front || position == :back || position == :none
    articles = ["the", "a", "an"]
    articles.each do |a|
      starts = str.downcase.start_with?(a + ' ')
      ends = str.downcase.end_with?(' ' + a)
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
end
