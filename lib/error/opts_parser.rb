module BBLib
  class OptsParserException < StandardError
    # Nothing...
  end
end

require_relative 'opts_parser/invalid_argument'
require_relative 'opts_parser/missing_argument'
require_relative 'opts_parser/missing_required_argument'
