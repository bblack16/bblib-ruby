require_relative 'matching'
require_relative 'roman'
require_relative 'cases'
require_relative 'regexp'
require_relative 'pluralization'

module BBLib
  # Quickly remove any symbols from a string leaving only alpha-numeric characters and white space.
  def self.drop_symbols(str)
    str.gsub(/[^\w\s\d]|_/, '')
  end

  # Extract all integers from a string. Use extract_floats if numbers may contain decimal places.
  def self.extract_integers(str, convert: true)
    BBLib.extract_numbers(str, convert: false).reject { |r| r.include?('.') }
         .map { |m| convert ? m.to_i : m }
  end

  # Extracts all integers or decimals from a string into an array.
  def self.extract_floats(str, convert: true)
    BBLib.extract_numbers(str, convert: false).reject { |r| !r.include?('.') }
         .map { |m| convert ? m.to_f : m }
  end

  # Extracts any correctly formed integers or floats from a string
  def self.extract_numbers(str, convert: true)
    str.scan(/(?<=[^\.]|^)\d+\.\d+(?=[^\.]|$)|(?<=[^\.\d\w]|^)\d+(?=[^\.\d\w]|$)/)
       .map { |f| convert ? (f.include?('.') ? f.to_f : f.to_i) : f }
  end

  # Used to move the position of the articles 'the', 'a' and 'an' in strings for normalization.
  def self.move_articles(str, position = :front, capitalize: true)
    return str unless [:front, :back, :none].include?(position)
    %w(the a an).each do |a|
      starts = str.downcase.start_with?(a + ' ')
      ends = str.downcase.end_with?(' ' + a)
      if starts && position != :front
        if position == :none
          str = str[(a.length + 1)..str.length]
        elsif position == :back
          str = str[(a.length + 1)..str.length] + (!ends ? ", #{capitalize ? a.capitalize : a}" : '')
        end
      end
      next unless ends && position != :back
      if position == :none
        str = str[0..-(a.length + 2)]
      elsif position == :front
        str = (!starts ? "#{capitalize ? a.capitalize : a} " : '') + str[0..-(a.length + 2)]
      end
    end
    str = str.strip.chop while str.strip.end_with?(',')
    str
  end

  # Displays a portion of an object (as a string) with an ellipse displayed
  # if the string is over a certain size.
  # Supported styles:
  # => front - "for exam..."
  # => back - "... example"
  # => middle - "... exam..."
  # => outter - "for e...ple"
  # The length of the too_long string is NOT factored into the cap
  def self.chars_up_to(str, cap, too_long = '...', style: :front)
    return str if str.to_s.size <= cap
    str = str.to_s
    case style
    when :back
      "#{too_long}#{str[(str.size - cap)..-1]}"
    when :outter
      "#{str[0...(cap / 2).to_i + (cap.odd? ? 1 : 0)]}#{too_long}#{str[-(cap / 2).to_i..-1]}"
    when :middle
      "#{too_long}#{str[(str.size / 2 - cap / 2 - (cap.odd? ? 1 : 0)).to_i...(str.size / 2 + cap / 2).to_i]}#{too_long}"
    else
      "#{str[0...cap]}#{too_long}"
    end
  end

  # Takes two strings and tries to apply the same capitalization from
  # the first string to the second.
  # Supports lower case, upper case and capital case
  def self.copy_capitalization(str_a, str_b)
    str_a = str_a.to_s
    str_b = str_b.to_s
    if str_a.upper?
      str_b.upcase
    elsif str_a.lower?
      str_b.downcase
    elsif str_a.capital?
      str_b.capitalize
    else
      str_b
    end
  end

  # Pattern render takes (by default) a mustache style template and then uses
  # a context (either a Hash or Object) to then interpolate in placeholders.
  # The default pattern looks for {{method_name}} within the string but can be
  # customized to a different pattern by setting the pattern named argument.
  def self.pattern_render(text, context = {})
    raise ArgumentError, "Expected text argument to be a String, got a #{text.class}" unless text.is_a?(String)
    # TODO Make patterns customizable
    pattern       = /\{{2}.*?\}{2}/
    field_pattern = /(?<=^\{{2}).*(?=\}{2})/
    txt           = text.dup
    txt.scan(pattern).each do |match|
      field = match.scan(field_pattern).first
      next unless field
      value = case context
      when Hash
        context.hpath(field).first
      else
        context.send(field) if context.respond_to?(field)
      end.to_s
      txt.sub!(match, value)
    end
    txt
  end
end

class String
  # Multi-split. Similar to split, but can be passed an array of delimiters to split on.
  def msplit(*delims)
    ary = [self]
    return ary if delims.empty?
    delims.flatten.each do |d|
      ary = ary.flat_map { |a| a.split d }
    end
    ary
  end

  # Split on delimiters
  def quote_split(*delimiters)
    encap_split(%w{" '}, *delimiters)
  end

  alias qsplit quote_split

  # Split on only delimiters not between specific encapsulators
  # Various characters are special and automatically recognized such as parens
  # which automatically match anything between a begin and end character.
  #
  # Regex below is no longer used because of how inefficient it is.
  # Comment is left in case it is ever useful again
  # /(?<group>\((?:[^\(\)]*|\g<group>)*\)[^\(\)]*?),|,(?<=[^\(\)|$])/
  def encap_split(expressions, *delimiters, **opts)
    BBLib::Splitter.split(self, *delimiters, **opts.merge(expressions: expressions))
  end

  alias esplit encap_split

  def move_articles(position = :front, capitalize = true)
    BBLib.move_articles self, position, capitalize: capitalize
  end

  def move_articles!(position = :front, capitalize = true)
    replace BBLib.move_articles(self, position, capitalize: capitalize)
  end

  def drop_symbols
    BBLib.drop_symbols self
  end

  def drop_symbols!
    replace BBLib.drop_symbols(self)
  end

  def extract_integers(convert: true)
    BBLib.extract_integers self, convert: convert
  end

  def extract_floats(convert: true)
    BBLib.extract_floats self, convert: convert
  end

  def extract_numbers(convert: true)
    BBLib.extract_numbers self, convert: convert
  end

  def to_clean_sym
    snake_case.to_sym
  end

  # Simple method to convert a string into an array containing only itself
  def to_a
    [self]
  end

  def encap_by?(str)
    case str
    when '('
      start_with?(str) && end_with?(')')
    when '['
      start_with?(str) && end_with?(']')
    when '{'
      start_with?(str) && end_with?('}')
    when '<'
      start_with?(str) && end_with?('>')
    else
      start_with?(str) && end_with?(str)
    end
  end

  def encapsulate(char = '"')
    back = case char
           when '('
             ')'
           when '['
             ']'
           when '{'
             '}'
           when '<'
             '>'
           else
             char
           end
     "#{char}#{self}#{back}"
  end

  def uncapsulate(char = '"', limit: nil)
    back = case char
           when '('
             ')'
           when '['
             ']'
           when '{'
             '}'
           when '<'
             '>'
           else
             char
           end
    temp = dup
    count = 0
    while temp.start_with?(char) && temp != char && (limit.nil? || count < limit)
      temp = temp[(char.size)..-1]
      count += 1
    end
    count = 0
    while temp.end_with?(back) && temp != char && (limit.nil? || count < limit)
      temp = temp[0..-(char.size + 1)]
      count += 1
    end
    temp
  end

  def upper?
    chars.all? { |letter| /[[:upper:]]|\W/.match(letter) }
  end

  def lower?
    chars.all? { |letter| /[[:lower:]]|\W/.match(letter) }
  end

  def capital?
    chars.first.upper?
  end
end

class Symbol
  def to_clean_sym
    to_s.to_clean_sym
  end
end
