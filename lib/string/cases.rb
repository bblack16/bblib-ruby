module BBLib
  def self.title_case(str, first_only: true)
    str = str.to_s unless str.is_a?(String)
    ignoreables = %w(a an the on upon and but or in with to)
    regx = /[[:space:]]+|\-|\_|\"|\'|\(|\)|\[|\]|\{|\}|\#/
    spacing = str.scan(regx).to_a
    words = str.split(regx).map do |word|
      if ignoreables.include?(word.downcase)
        word.downcase
      elsif first_only
        word[0] = word[0].to_s.upcase
        word
      else
        word.capitalize
      end
    end
    # Always cap the first word
    first = words.first.to_s
    first[0] = first[0].to_s.upcase
    words[0] = first
    words.interleave(spacing).join
  end

  def self.start_case(str, first_only: false)
    regx = /[[:space:]]+|\-|\_|\"|\'|\(|\)|\[|\]|\{|\}|\#/
    spacing = str.scan(regx).to_a
    words = str.split(regx).map do |word|
      if first_only
        word[0] = word[0].upcase
        word
      else
        word.capitalize
      end
    end
    words.interleave(spacing).join
  end

  def self.camel_case(str, style = :lower)
    regx = /[[:space:]]+|[^[[:alnum:]]]+/
    words = str.split(regx).map(&:capitalize)
    words[0].downcase! if style == :lower
    words.join
  end

  def self.delimited_case(str, delimiter = '_')
    regx = /[[:space:]]+|[^[[:alnum:]]]+|\#{delimiter}+/
    str.split(regx).join(delimiter)
  end

  def self.snake_case(str)
    BBLib.delimited_case str, '_'
  end

  def self.method_case(str)
    str.gsub(/(?<=[^^])([A-Z])/, '_\1').gsub(/\s+/, ' ').snake_case.downcase
  end

  def self.spinal_case(str)
    BBLib.delimited_case str, '-'
  end

  def self.train_case(str)
    BBLib.spinal_case(BBLib.start_case(str))
  end
end

class String
  def title_case(first_only: false)
    BBLib.title_case self, first_only: first_only
  end

  def start_case(first_only: false)
    BBLib.start_case self, first_only: first_only
  end

  def camel_case(style = :lower)
    BBLib.camel_case self, style
  end

  def delimited_case(delimiter = '_')
    BBLib.delimited_case self, delimiter
  end

  def snake_case
    BBLib.snake_case self
  end

  def method_case
    BBLib.method_case(self)
  end

  def spinal_case
    BBLib.spinal_case self
  end

  def train_case
    BBLib.train_case self
  end
end
