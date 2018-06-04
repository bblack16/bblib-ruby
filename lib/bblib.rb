require_relative 'bblib/version'
require_relative 'opal/bbopal'
require_relative 'object/bbobject'
require_relative 'hash/bbhash'
require_relative 'mixins/bbmixins'
require_relative 'class/effortless'
require_relative 'hash_path/hash_path'
require_relative 'string/bbstring'
require_relative 'file/bbfile'
require_relative 'time/bbtime'
require_relative 'number/bbnumber'
require_relative 'array/bbarray'
require_relative 'system/bbsystem'
require_relative 'logging/bblogging'
require_relative 'error/abstract'
require_relative 'html/bbhtml'
require_relative 'cli/color'

non_opal = ['os/bbos']

non_opal.each { |i| require_relative i } unless BBLib.in_opal?

require 'fileutils'
require 'time'
# require 'logger'

module BBLib
  CONFIGS_PATH = 'config/'.freeze
end
