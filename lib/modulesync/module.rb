require 'modulesync'
require 'modulesync/util'
require 'modulesync/git/repo'
require 'modulesync/modulefile'

module ModuleSync
  class Module
    attr_accessor :name, :project, :module_config_file, :opts, :pending

    def initialize(name, project, opts = nil)
      @name = name
      @project = project
      @module_config_file = File.join(path, '.sync.yml')
      @opts = opts || {}
    end

    def project_config
      project.config
    end

    def project_root
      project.root
    end

    def defaults
      project.defaults
    end

    def global_defaults
      project.global_defaults
    end

    def project_hooks
      project.hooks || {}
    end

    def git_opts
      project_config['git_opts']
    end

    def hooks
      opts['hooks'] ? project_hooks.merge(ModuleSync.validate_hooks(opts['hooks'], project_root)) : project_hooks
    end

    def git_base
      opts['git_base'] ? opts['git_base'] : project_config['git_base']
    end

    def namespace
      opts['namespace'] ? opts['namespace'] : project_config['namespace']
    end

    def branch
      opts['branch'] ? opts['branch'] : project_config['branch']
    end

    def remote_branch
      opts['remote_branch'] ? opts['remote_branch'] : project_config['remote_branch']
    end

    def moduleroot
      project.moduleroot
    end

    def source_files
      @source_files ||= project.moduleroot.source_files
    end

    def noop
      project_config['noop']
    end

    def path
      @path ||= File.join(project_config['modules_dir'], name)
    end

    def module_configs
      @module_configs ||= Util.parse_config(module_config_file)
    end

    def global_defaults_key
      project_config['global_defaults_key']
    end

    def module_defaults
      module_configs[global_defaults_key] || {}
    end

    def files
      return @files if @files
      files = source_files.map { |file| file.sub(/#{moduleroot.path}\//, '') }
      @files = (files | defaults.keys | module_configs.keys) - [global_defaults_key]
    end

    def file_configs(file)
      global_defaults.merge(defaults[file] || {}).merge(module_defaults).merge(module_configs[file] || {})
    end

    def sync
      synced = []
      files.each do |file|
        configs = file_configs(file)
        if configs['unmanaged']
          puts "Not managing #{file} in #{name}"
        elsif configs['delete']
          f = ModuleSync::ModuleFile.new(self, file)
          f.delete!
        else
          f = ModuleSync::ModuleFile.new(self, file, configs)
          written = f.write
          synced << written if written
        end
      end

      synced
    end

    def update
      puts "Syncing #{name}"
      repo = Git::Repo.new(self, noop, opts, git_opts)
      @pending = sync
      repo.commit
    end
  end
end
