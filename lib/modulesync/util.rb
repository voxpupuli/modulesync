require 'yaml'

module ModuleSync
  module Util
    def self.symbolize_keys(hash)
      hash.inject({}) do |memo, (k, v)|
        memo[k.to_sym] = v.is_a?(Hash) ? symbolize_keys(v) : v
        memo
      end
    end

    def self.parse_config(config_file)
      if File.exist?(config_file)
        YAML.load_file(config_file) || {}
      else
        puts "No config file under #{config_file} found, using default values"
        {}
      end
    end

    def self.parse_list(option_value)
      if option_value.is_a? String
        option_value.split(',')
      elsif option_value.is_a? Array
        option_value
      else
        []
      end
    end
  end
end
