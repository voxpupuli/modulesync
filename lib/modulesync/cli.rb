require 'thor'
require 'modulesync/hook'
require 'modulesync/util'
require 'modulesync/project'
require 'modulesync/version'
require 'find'

module ModuleSync
  module CLI
    class Hook < Thor
      class_option :project_root, :aliases => '-c', :desc => 'The directory that contains a list of managed modules, file templates, and default values for template variables.', :default => Dir.pwd

      desc 'activate', 'activate a git hook'
      def activate
        project = Project.new(options[:project_root])
        ModuleSync::Hook.new(project.hook_file, project.config['namespace'], project.config['branch']).activate
      end

      desc 'deactivate', 'deactivate a git hook'
      def deactivate
        project = Project.new(options[:project_root])
        ModuleSync::Hook.new(project.hook_file).deactivate
      end
    end

    class List < Thor
      class_option :project_root, :aliases => '-c', :desc => 'The directory that contains a list of managed modules, file templates, and default values for template variables.', :default => Dir.pwd

      desc 'modules', 'List the modules in managed_modules.yml'
      def modules
        modules = Util.parse_config(File.join(options[:project_root], 'managed_modules.yml'))
        puts modules.join("\n") unless modules.empty?
      end

      desc 'files', 'List the files in the moduleroot'
      def files
        puts ModuleSync::ModuleRoot.new(File.join(options[:project_root], 'moduleroot')).source_files.join("\n")
      end
    end

    class Base < Thor
      class_option :project_root, :aliases => '-c', :desc => 'The directory that contains a list of managed modules, file templates, and default values for template variables.', :default => Dir.pwd

      desc 'version', 'Print the version'
      def version
        puts ModuleSync::VERSION
      end

      desc 'update', 'Update the modules in managed_modules.yml'
      option :message, :aliases => '-m', :desc => 'Commit message to apply to updated modules. Required unless running in noop mode.'
      option :noop, :type => :boolean, :default => false, :desc => 'No-op mode'
      option :namespace, :aliases => '-n', :desc => 'Remote github namespace (user or organization) to clone from and push to. Defaults to puppetlabs.'
      option :branch, :aliases => '-b', :desc => 'Branch name to make the changes in. Defaults to master.'
      option :remote_branch, :aliases => '-r', :desc => 'Remote branch name to push the changes to. Defaults to the branch name.'
      option :filter, :aliases => '-f', :desc => 'A regular expression to filter repositories to update.'
      def update
        config = {}

        fail MalformattedArgumentError, 'No value provided for required options "--message"' unless options[:noop] || options[:message]

        config['noop'] = options[:noop]

        [:message, :namespace, :branch, :remote_branch, :filter].each do |opt|
          config[opt.to_s] = options[opt] if options[opt]
        end

        project = Project.new(options[:project_root], config)

        project.modules.each(&:update)
      end

      desc 'list', 'List managed modules, files, etc...'
      subcommand 'list', ModuleSync::CLI::List

      desc 'hook [activate|deactivate]', 'Activate or deactivate the git hook'
      subcommand 'hook', ModuleSync::CLI::Hook
    end
  end
end
