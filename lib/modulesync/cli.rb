require 'thor'
require 'modulesync'
require 'modulesync/util'
require 'modulesync/config'

module ModuleSync
  class CLI
    class Hook < Thor
      class_option :project_root, :aliases => '-c', :desc => 'The directory that contains a list of managed modules, file templates, and default values for template variables.', :default => Dir.pwd
      class_option :hook_args, :aliases => '-a', :desc => 'Arguments to pass to msync in the git hook'

      desc 'activate', 'Activate the git hook.'
      def activate
        config = ModuleSync::Config.new(options[:project_root], options)
        config[:command] = 'hook'
        config[:hook] = 'activate'
        ModuleSync.hook(config)
      end

      desc 'deactivate', 'Deactivate the git hook.'
      def deactivate
        config = ModuleSync::Config.new(options[:project_root], options)
        config[:command] = 'hook'
        config[:hook] = 'deactivate'
        ModuleSync.hook(config)
      end
    end

    class Base < Thor
      class_option :project_root, :aliases => '-c', :desc => 'The directory that contains a list of managed modules, file templates, and default values for template variables.', :default => Dir.pwd
      class_option :namespace, :aliases => '-n', :desc => 'Remote github namespace (user or organization) to clone from and push to. Defaults to puppetlabs'
      class_option :filter, :aliases => '-f', :desc => 'A regular expression to filter repositories to update.'
      class_option :branch, :aliases => '-b', :desc => 'Branch name to make the changes in. Defaults to master.'

      desc 'update', 'Update the modules in managed_modules.yml'
      option :modules_dir, :aliases => '-w', :desc => 'The directory where the modules should be cloned and synced. Defaults to ./modules'
      option :message, :aliases => '-m', :desc => 'Commit message to apply to updated modules. Required unless running in noop mode.'
      option :remote_branch, :aliases => '-r', :desc => 'Remote branch name to push the changes to. Defaults to the branch name.'
      option :amend, :type => :boolean, :desc => 'Amend previous commit'
      option :force, :type => :boolean, :desc => 'Force push amended commit'
      option :noop, :type => :boolean, :desc => 'No-op mode'
      option :offline, :type => :boolean, :desc => 'Do not run any Git commands. Allows the user to manage Git outside of ModuleSync.'
      option :bump, :type => :boolean, :desc => 'Bump module version to the next minor'
      option :changelog, :type => :boolean, :desc => 'Update CHANGELOG.md if version was bumped'
      option :tag, :type => :boolean, :desc => 'Git tag with the current module version'
      option :tag_pattern, :desc => 'The pattern to use when tagging releases.'

      def update
        config = ModuleSync::Config.new(options[:project_root], options)
        config[:command] = 'update'
        fail Thor::Error, 'No value provided for required option "--message"' unless config[:noop] || config[:message] || config[:offline]
        config[:git_opts] = { 'amend' => config[:amend], 'force' => config[:force] }
        ModuleSync.update(config)
      end

      desc 'hook', 'Activate or deactivate a git hook.'
      subcommand 'hook', ModuleSync::CLI::Hook
    end
  end
end
