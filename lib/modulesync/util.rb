require 'yaml'

module ModuleSync
  module Util
    def self.symbolize_keys(hash)
      hash.each_with_object({}) do |(k, v), memo|
        memo[k.to_sym] = v.is_a?(Hash) ? symbolize_keys(v) : v
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
      case option_value
      when String
        option_value.split(',')
      when Array
        option_value
      else
        []
      end
    end
  end
end
