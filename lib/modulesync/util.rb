require 'yaml'

module ModuleSync
  module Util

    def self.parse_config(config_file)
      if File.exist?(config_file)
        YAML.load_file(config_file) || {}
      else
        puts "No config file under #{config_file} found, using default values"
        {}
      end
    end
  end
end

class Hash
  #take keys of hash and transform those to a symbols
  def self.transform_keys_to_symbols(value)
    return value if not value.is_a?(Hash)
    hash = value.inject({}){|memo,(k,v)| memo[k.to_sym] = Hash.transform_keys_to_symbols(v); memo}
    return hash
  end
end
