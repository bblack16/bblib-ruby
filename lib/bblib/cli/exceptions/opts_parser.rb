module BBLib
  class OptsParserException < Exception
    # Nothing...
  end
end

require_relative 'invalid_argument'
require_relative 'missing_argument'
require_relative 'missing_required_argument'
