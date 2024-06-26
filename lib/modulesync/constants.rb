# frozen_string_literal: true

module ModuleSync
  module Constants
    MODULE_FILES_DIR     = 'moduleroot/'
    CONF_FILE            = 'config_defaults.yml'
    MODULE_CONF_FILE     = '.sync.yml'
    MODULESYNC_CONF_FILE = 'modulesync.yml'
    HOOK_FILE            = '.git/hooks/pre-push'
    GLOBAL_DEFAULTS_KEY  = :global
  end
end
