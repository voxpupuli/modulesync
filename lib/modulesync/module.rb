require 'modulesync'
require 'modulesync/util'
require 'modulesync/git/repo'
require 'modulesync/modulefile'

module ModuleSync
  class Module
    attr_accessor :name, :project, :path, :source_files, :project_configs,
                  :global_configs_key, :module_config_file, :noop, :pending, :git_opts

    def initialize(name, project, git_opts = nil)
      @name = name
      @project = project
      @path = File.join(@project.config['modules_dir'], name)
      @source_files = @project.moduleroot.source_files
      @project_configs = @project.configs
      @global_configs_key = @project.config['global_configs_key']
      @module_config_file = File.join(@path, '.sync.yml')
      @noop = @project.config['noop']
      @git_opts = git_opts || {}
    end

    def module_configs
      @module_configs ||= Util.parse_config(module_config_file)
    end

    def global_configs
      @global_configs ||= module_configs[global_configs_key] || {}
    end

    def configs
      @cfgs ||= project_configs.merge(global_configs.merge(module_configs)).reject { |k, _| k if k == global_configs_key }
    end

    def files
      return @files if @files
      files = source_files.map { |file| file.sub(/#{path}\//, '') }
      @files = (files | configs.keys) - [global_configs_key]
    end

    def sync
      pending = []
      files.each do |file|
        if (file_configs = configs[file])
          if file_configs['unmanaged']
            puts "Not managing #{file} in #{name}"
          elsif file_configs['delete']
            f = ModuleSync::ModuleFile.new(self, file)
            f.delete!
          else
            f = ModuleSync::ModuleFile.new(self, file)
            pending << f.write
          end
        end
      end

      pending
    end

    def update
      puts "Syncing #{name}"
      repo = Git::Repo.new(self, noop, git_opts)
      @pending = sync
      repo.commit
    end
  end
end
