require 'yaml'

module ModuleSync
  module Util
    def self.symbolize_keys(hash)
      hash.inject({}) { |memo, (k, v)| memo[k.to_sym] = v; memo }
    end

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
