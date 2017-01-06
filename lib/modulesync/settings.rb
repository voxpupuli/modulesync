
module ModuleSync
  # Encapsulate a configs for a module, providing easy access to its parts
  class Settings
    attr_reader :global_defaults, :defaults, :module_defaults, :module_configs, :additional_settings

    def initialize(global_defaults, defaults, module_defaults, module_configs, additional_settings)
      @global_defaults = global_defaults
      @defaults = defaults
      @module_defaults = module_defaults
      @module_configs = module_configs
      @additional_settings = additional_settings
    end

    def build_file_configs(filename)
      global_defaults.merge(defaults[filename] || {}).merge(module_defaults).merge(module_configs[filename] || {}).merge(additional_settings)
    end

    def managed?(filename)
      Pathname.new(filename).ascend do |v|
        configs = build_file_configs(v.to_s)
        return false if configs['unmanaged']
      end
      true
    end

    # given a list of existing files in the repo, return everything that we might want to act on
    def managed_files(file_list)
      (file_list | defaults.keys | module_configs.keys).select do |f|
        (f != ModuleSync::GLOBAL_DEFAULTS_KEY) && managed?(f)
      end
    end

    # returns a list of files that should not be touched
    def unmanaged_files(file_list)
      (file_list | defaults.keys | module_configs.keys).select do |f|
        (f != ModuleSync::GLOBAL_DEFAULTS_KEY) && !managed?(f)
      end
    end
  end
end
