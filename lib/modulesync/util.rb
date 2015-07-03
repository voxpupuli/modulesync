require 'yaml'

module ModuleSync
  module Util
    def self.parse_config(config_file)
      if File.exist?(config_file)
        load_yaml(config_file) || {}
      else
        warn "No config file under #{config_file} found, using default values"
        {}
      end
    end

    def self.load_yaml(file)
      YAML.load_file(file)
    end
  end
end
