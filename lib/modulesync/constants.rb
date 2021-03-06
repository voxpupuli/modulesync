module ModuleSync
  module Constants
    MODULE_FILES_DIR     = 'moduleroot/'.freeze
    CONF_FILE            = 'config_defaults.yml'.freeze
    MODULE_CONF_FILE     = '.sync.yml'.freeze
    MODULESYNC_CONF_FILE = 'modulesync.yml'.freeze
    HOOK_FILE            = '.git/hooks/pre-push'.freeze
    GLOBAL_DEFAULTS_KEY  = :global
  end
end
