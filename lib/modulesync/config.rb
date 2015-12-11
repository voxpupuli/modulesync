require 'modulesync/util'

module ModuleSync
  # This is a config class. It holds your configz.
  class Config
    attr_reader :project_root

    def initialize(project_root, settings = {})
      @project_root = project_root
      @settings = Util.symbolize_keys(settings)
      @config_file = @settings[:config_file] || File.join(@project_root, 'modulesync.yml')
      @config = File.exist?(@config_file) ? load_config : defaults.merge(@settings)
    end

    def [](key)
      key.is_a?(String) ? @config[key.to_sym] : @config[key]
    end

    def []=(key, value)
      @config[key.to_sym] = value
    end

    def to_h
      @config.to_h
    end

    private

    def load_config
      defaults.merge(Util.symbolize_keys(Util.parse_config(@config_file)).merge(@settings))
    end

    def defaults
      {
        :moduleroot_dir       => File.join(project_root, 'moduleroot/'),
        :modules_dir          => File.join(project_root, 'modules'),
        :defaults_file        => File.join(project_root, 'config_defaults.yml'),
        :managed_modules_file => File.join(project_root, 'managed_modules.yml'),
        :hook_file            => File.join(project_root, '.git/hooks/pre-push'),
        :branch               => 'master',
        :namespace            => 'puppetlabs',
        :git_base             => 'git@github.com:',
        :tag_pattern          => '%s',
        :module_conf_file     => '.sync.yml',
        :global_defaults_key  => :global
      }
    end
  end
end
