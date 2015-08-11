require 'modulesync'
require 'modulesync/moduleroot'
require 'modulesync/module'

module ModuleSync
  class Project
    attr_writer :module_list
    attr_accessor :root, :settings, :config_file

    def initialize(root = Dir.pwd, settings = nil)
      @root = root
      @settings = settings || {}
      @config_file = @settings['config_file'] || File.join(@root, 'modulesync.yml')
    end

    def default_settings
      {
        'module_conf_file'     => '.sync.yml',
        'namespace'            => 'puppetlabs',
        'branch'               => 'master',
        'git_base'             => 'git@github.com:',
        'hook_file'            => File.join(root, '.git/hooks/pre-push'),
        'managed_modules_file' => File.join(root, 'managed_modules.yml'),
        'defaults_file'        => File.join(root, 'config_defaults.yml'),
        'modules_dir'          => File.join(root, 'modules'),
        'moduleroot_dir'       => File.join(root, 'moduleroot'),
        'global_defaults_key'  => :global
      }
    end

    def hooks
      return nil unless config['hooks']
      return @hooks if @hooks
      @hooks ||= ModuleSync.validate_hooks(config['hooks'], root)
    end

    def moduleroot
      @moduleroot ||= ModuleSync::ModuleRoot.new(config['moduleroot_dir'])
    end

    def defaults
      @defaults ||= Util.parse_config(config['defaults_file'])
    end

    def global_defaults
      @global_defaults ||= defaults[config['global_defaults_key']] || {}
    end

    def config
      return @config if @config

      @config = default_settings.merge(Util.parse_config(config_file).merge(settings))
    end

    def hook_file
      config['hook_file']
    end

    def modules
      managed = []
      module_list.each do |mod, opts|
        managed << ModuleSync::Module.new(mod, self, opts)
      end
      managed
    end

    def module_list
      return @module_list if @module_list
      fail FileNotFound, "#{config['managed_modules_file']} doesn't exist!" unless File.exist? config['managed_modules_file']
      @module_list = Util.parse_config(config['managed_modules_file'])
      fail FileNotFound, "No modules found in #{config['managed_modules_file']}. Add modules to manage and try again!" if @module_list.empty?
      @module_list.select! { |m| m =~ Regexp.new(config['filter']) } if config['filter']
      @module_list
    end
  end
end
