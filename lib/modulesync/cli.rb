require 'thor'
require 'modulesync'
require 'modulesync/constants'
require 'modulesync/util'

module ModuleSync
  class CLI
    class Hook < Thor
      class_option :project_root, :aliases => '-c', :desc => 'Path used by git to clone modules into. Defaults to "modules"', :default => 'modules'

      desc 'activate', 'Activate a git hook.'
      def activate
        config = { :command => 'hook' }.merge(options)
        config[:hook] = 'activate'
        ModuleSync.run(config)
      end

      desc 'deactivate', 'Deactivate a git hook.'
      def deactivate
        config = { :command => 'hook' }.merge(options)
        config[:hook] = 'deactivate'
        ModuleSync.run(config)
      end
    end

    class Base < Thor
      include Constants

      class_option :project_root, :aliases => '-c', :desc => 'Path used by git to clone modules into. Defaults to "modules"', :default => 'modules'

      desc 'update', 'Update the modules in managed_modules.yml'
      option :message, :aliases => '-m', :desc => 'Commit message to apply to updated modules. Required unless running in noop mode.'
      option :namespace, :aliases => '-n', :desc => 'Remote github namespace (user or organization) to clone from and push to. Defaults to puppetlabs', :default => 'puppetlabs'
      option :configs, :aliases => '-c', :desc => 'The local directory or remote repository to define the list of managed modules, the file templates, and the default values for template variables.'
      option :branch, :aliases => '-b', :desc => 'Branch name to make the changes in. Defaults to master.', :default => 'master'
      option :remote_branch, :aliases => '-r', :desc => 'Remote branch name to push the changes to. Defaults to the branch name.'
      option :filter, :aliases => '-f', :desc => 'A regular expression to filter repositories to update.'
      option :amend, :type => :boolean, :desc => 'Amend previous commit', :default => false
      option :force, :type => :boolean, :desc => 'Force push amended commit', :default => false
      option :noop, :type => :boolean, :desc => 'No-op mode', :default => false
      option :offline, :type => :boolean, :desc => 'Do not run any Git commands. Allows the user to manage Git outside of ModuleSync.', :default => false
      option :bump, :type => :boolean, :desc => 'Bump module version to the next minor', :default => false
      option :changelog, :type => :boolean, :desc => 'Update CHANGELOG.md if version was bumped', :default => false
      option :tag, :type => :boolean, :desc => 'Git tag with the current module version', :defalut => false
      option :tag_pattern, :desc => 'The pattern to use when tagging releases.'

      def update
        config = { :command => 'update' }.merge(options)
        config.merge!(Util.parse_config(MODULESYNC_CONF_FILE))
        config = Util.symbolize_keys(config)
        fail Thor::Error, 'No value provided for required option "--message"' unless config[:noop] || config[:message] || config[:offline]
        config[:git_opts] = { 'amend' => config[:amend], 'force' => config[:force] }
        ModuleSync.run(config)
      end

      desc 'hook', 'Activate or deactivate a git hook.'
      subcommand 'hook', ModuleSync::CLI::Hook
    end
  end
end
