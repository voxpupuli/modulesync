
module ModuleSync
  # Encapsulate a configs for a module, providing easy access to its parts
  # All configs MUST be keyed by the relative target filename
  class Settings
    attr_reader :global_defaults, :defaults, :module_defaults, :module_configs, :additional_settings

    def initialize(global_defaults, defaults, module_defaults, module_configs, additional_settings)
      @global_defaults = global_defaults
      @defaults = defaults
      @module_defaults = module_defaults
      @module_configs = module_configs
      @additional_settings = additional_settings
    end

    def lookup_config(hash, target_name)
      hash[target_name] || {}
    end

    def build_file_configs(target_name)
      file_def = lookup_config(defaults, target_name)
      file_mc  = lookup_config(module_configs, target_name)

      global_defaults.merge(file_def).merge(module_defaults).merge(file_mc).merge(additional_settings)
    end

    def managed?(target_name)
      Pathname.new(target_name).ascend do |v|
        configs = build_file_configs(v.to_s)
        return false if configs['unmanaged']
      end
      true
    end

    # given a list of templates in the repo, return everything that we might want to act on
    def managed_files(target_name_list)
      (target_name_list | defaults.keys | module_configs.keys).select do |f|
        (f != ModuleSync::GLOBAL_DEFAULTS_KEY) && managed?(f)
      end
    end

    # returns a list of templates that should not be touched
    def unmanaged_files(target_name_list)
      (target_name_list | defaults.keys | module_configs.keys).select do |f|
        (f != ModuleSync::GLOBAL_DEFAULTS_KEY) && !managed?(f)
      end
    end
  end
end
