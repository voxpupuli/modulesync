require 'thor'

require 'modulesync'
require 'modulesync/cli/thor'
require 'modulesync/constants'
require 'modulesync/util'

module ModuleSync
  module CLI
    def self.defaults
      @defaults ||= Util.symbolize_keys(Util.parse_config(Constants::MODULESYNC_CONF_FILE))
    end

    class Hook < Thor
      option :hook_args,
             :aliases => '-a',
             :desc => 'Arguments to pass to msync in the git hook'
      option :branch,
             :aliases => '-b',
             :desc => 'Branch name to pass to msync in the git hook',
             :default => CLI.defaults[:branch]
      desc 'activate', 'Activate the git hook.'
      def activate
        config = { :command => 'hook' }.merge(options)
        config[:hook] = 'activate'
        ModuleSync.hook(config)
      end

      desc 'deactivate', 'Deactivate the git hook.'
      def deactivate
        config = { :command => 'hook' }.merge(options)
        config[:hook] = 'deactivate'
        ModuleSync.hook(config)
      end
    end

    class Base < Thor
      class_option :project_root,
                   :aliases => '-c',
                   :desc => 'Path used by git to clone modules into.',
                   :default => CLI.defaults[:project_root] || 'modules'
      class_option :git_base,
                   :desc => 'Specify the base part of a git URL to pull from',
                   :default => CLI.defaults[:git_base] || 'git@github.com:'
      class_option :namespace,
                   :aliases => '-n',
                   :desc => 'Remote github namespace (user or organization) to clone from and push to.',
                   :default => CLI.defaults[:namespace] || 'puppetlabs'
      class_option :filter,
                   :aliases => '-f',
                   :desc => 'A regular expression to select repositories to update.'
      class_option :negative_filter,
                   :aliases => '-x',
                   :desc => 'A regular expression to skip repositories.'
      class_option :verbose,
                   :aliases => '-v',
                   :desc => 'Verbose mode',
                   :type => :boolean,
                   :default => false

      desc 'update', 'Update the modules in managed_modules.yml'
      option :message,
             :aliases => '-m',
             :desc => 'Commit message to apply to updated modules. Required unless running in noop mode.',
             :default => CLI.defaults[:message]
      option :configs,
             :aliases => '-c',
             :desc => 'The local directory or remote repository to define the list of managed modules,' \
                      ' the file templates, and the default values for template variables.'
      option :managed_modules_conf,
             :desc => 'The file name to define the list of managed modules'
      option :remote_branch,
             :aliases => '-r',
             :desc => 'Remote branch name to push the changes to. Defaults to the branch name.',
             :default => CLI.defaults[:remote_branch]
      option :skip_broken,
             :type => :boolean,
             :aliases => '-s',
             :desc => 'Process remaining modules if an error is found',
             :default => false
      option :amend,
             :type => :boolean,
             :desc => 'Amend previous commit',
             :default => false
      option :force,
             :type => :boolean,
             :desc => 'Force push amended commit',
             :default => false
      option :noop,
             :type => :boolean,
             :desc => 'No-op mode',
             :default => false
      option :pr,
             :type => :boolean,
             :desc => 'Submit pull/merge request',
             :default => false
      option :pr_title,
             :desc => 'Title of pull/merge request',
             :default => CLI.defaults[:pr_title] || 'Update to module template files'
      option :pr_labels,
             :type => :array,
             :desc => 'Labels to add to the pull/merge request',
             :default => CLI.defaults[:pr_labels] || []
      option :pr_target_branch,
             :desc => 'Target branch for the pull/merge request',
             :default => CLI.defaults[:pr_target_branch]
      option :offline,
             :type => :boolean,
             :desc => 'Do not run any Git commands. Allows the user to manage Git outside of ModuleSync.',
             :default => false
      option :bump,
             :type => :boolean,
             :desc => 'Bump module version to the next minor',
             :default => false
      option :changelog,
             :type => :boolean,
             :desc => 'Update CHANGELOG.md if version was bumped',
             :default => false
      option :tag,
             :type => :boolean,
             :desc => 'Git tag with the current module version',
             :default => false
      option :tag_pattern,
             :desc => 'The pattern to use when tagging releases.'
      option :pre_commit_script,
             :desc => 'A script to be run before committing',
             :default => CLI.defaults[:pre_commit_script]
      option :fail_on_warnings,
             :type => :boolean,
             :aliases => '-F',
             :desc => 'Produce a failure exit code when there are warnings' \
                      ' (only has effect when --skip_broken is enabled)',
             :default => false
      option :branch,
             :aliases => '-b',
             :desc => 'Branch name to make the changes in.' \
                      ' Defaults to the default branch of the upstream repository, but falls back to "master".',
             :default => CLI.defaults[:branch]

      def update
        config = { :command => 'update' }.merge(options)
        config = Util.symbolize_keys(config)
        raise Thor::Error, 'No value provided for required option "--message"' unless config[:noop] \
                                                                                      || config[:message] \
                                                                                      || config[:offline]

        config[:git_opts] = { 'amend' => config[:amend], 'force' => config[:force] }
        ModuleSync.update(config)
      end

      desc 'execute COMMAND', 'Execute the command in each managed modules'
      option :configs,
             :aliases => '-c',
             :desc => 'The local directory or remote repository to define the list of managed modules,' \
                      ' the file templates, and the default values for template variables.'
      option :managed_modules_conf,
             :desc => 'The file name to define the list of managed modules'
      option :branch,
             :aliases => '-b',
             :desc => 'Branch name to make the changes in.',
             :default => CLI.defaults[:branch]

      def execute(*command_args)
        config = {
          :command => 'execute',
          :command_args => command_args,
        }.merge(options)
        config = Util.symbolize_keys(config)
        ModuleSync.execute(config)
      end

      desc 'hook', 'Activate or deactivate a git hook.'
      subcommand 'hook', ModuleSync::CLI::Hook
    end
  end
end
