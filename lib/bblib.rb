require_relative 'bblib/version'
require_relative 'opal/bbopal'
require_relative 'object/bbobject'
require_relative 'object/lazy_class'
require_relative 'string/bbstring'
require_relative 'file/bbfile'
require_relative 'time/bbtime'
require_relative 'hash/bbhash'
require_relative 'gem/bbgem'
require_relative 'number/bbnumber'
require_relative 'array/bbarray'

non_opal = ['os/bbos', 'gem/bbgem']

unless BBLib::in_opal?
  non_opal.each{ |i| require_relative i }
end


require 'fileutils'
# require 'uri'

module BBLib

  CONFIGS_PATH = 'config/'

end
