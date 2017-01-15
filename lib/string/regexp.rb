# frozen_string_literal: true
module BBLib
  REGEXP_MODE_HASH = {
    i: Regexp::IGNORECASE,
    m: Regexp::MULTILINE,
    x: Regexp::EXTENDED
  }.freeze

  REGEXP_OPTIONS = {
    i: [:ignore_case, :ignorecase, :i, :case_insensitive, Regexp::IGNORECASE],
    m: [:multiline, :multi_line, :m, Regexp::MULTILINE],
    x: [:extended, :x, Regexp::EXTENDED]
  }.freeze
end

class Regexp
  def self.from_s(str, *options, ignore_invalid: false)
    opt_map = options.map { |o| BBLib::REGEXP_OPTIONS.find { |k, v| o == k || o == k.to_s || v.include?(o) || v.include?(o.to_s.to_sym) }.first }.compact
    return Regexp.new(str, opt_map.inject(0) { |s, x| s += BBLib::REGEXP_MODE_HASH[x] }) if str.encap_by?('(') || !str.start_with?('/')
    str += opt_map.join
    mode = 0
    unless str.end_with?('/')
      str.split('/').last.chars.uniq.each do |l|
        raise ArgumentError, "Invalid Regexp mode: '#{l}'" unless ignore_invalid || BBLib::REGEXP_MODE_HASH[l.to_sym]
        mode += (BBLib::REGEXP_MODE_HASH[l.to_sym] || 0)
      end
      str = str[0..(str.rindex('/') || -1)]
    end
    Regexp.new(str.uncapsulate('/', limit: 1), mode)
  end
end

class String
  def to_regex(*options, ignore_invalid: false)
    Regexp.from_s(self, *options, ignore_invalid: ignore_invalid)
  end
end
