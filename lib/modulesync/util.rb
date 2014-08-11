require 'yaml'

module ModuleSync
  module Util

    def self.parse_config(config_file)
      if File.exist?(config_file)
        YAML.load_file(config_file) || {}
      else
        {}
      end
    end
  end
end
