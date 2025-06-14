# frozen_string_literal: true

require 'thor'

require 'modulesync'
require 'modulesync/cli/thor'
require 'modulesync/constants'
require 'modulesync/util'

module ModuleSync
  module CLI
    def self.prepare_options(cli_options, **more_options)
      options = CLI.defaults
      options.merge! Util.symbolize_keys(cli_options)
      options.merge! more_options

      Util.symbolize_keys options
    end

    def self.defaults
      @defaults ||= Util.symbolize_keys(Util.parse_config(Constants::MODULESYNC_CONF_FILE))
    end

    class Hook < Thor
      option :hook_args,
             aliases: '-a',
             desc: 'Arguments to pass to msync in the git hook'
      option :branch,
             aliases: '-b',
             desc: 'Branch name to pass to msync in the git hook',
             default: CLI.defaults[:branch]
      desc 'activate', 'Activate the git hook.'
      def activate
        ModuleSync.hook CLI.prepare_options(options, hook: 'activate')
      end

      desc 'deactivate', 'Deactivate the git hook.'
      def deactivate
        ModuleSync.hook CLI.prepare_options(options, hook: 'deactivate')
      end
    end

    class Base < Thor
      class_option :project_root,
                   aliases: '-c',
                   desc: 'Path used by git to clone modules into.',
                   default: CLI.defaults[:project_root]
      class_option :git_base,
                   desc: 'Specify the base part of a git URL to pull from',
                   default: CLI.defaults[:git_base] || 'git@github.com:'
      class_option :namespace,
                   aliases: '-n',
                   desc: 'Remote github namespace (user or organization) to clone from and push to.',
                   default: CLI.defaults[:namespace] || 'puppetlabs'
      class_option :filter,
                   aliases: '-f',
                   desc: 'A regular expression to select repositories to update.'
      class_option :negative_filter,
                   aliases: '-x',
                   desc: 'A regular expression to skip repositories.'
      class_option :verbose,
                   aliases: '-v',
                   desc: 'Verbose mode',
                   type: :boolean,
                   default: false

      desc 'update', 'Update the modules in managed_modules.yml'
      option :message,
             aliases: '-m',
             desc: 'Commit message to apply to updated modules. Required unless running in noop mode.',
             default: CLI.defaults[:message]
      option :configs,
             aliases: '-c',
             desc: 'The local directory or remote repository to define the list of managed modules, ' \
                   'the file templates, and the default values for template variables.'
      option :managed_modules_conf,
             desc: 'The file name to define the list of managed modules'
      option :remote_branch,
             aliases: '-r',
             desc: 'Remote branch name to push the changes to. Defaults to the branch name.',
             default: CLI.defaults[:remote_branch]
      option :skip_broken,
             type: :boolean,
             aliases: '-s',
             desc: 'Process remaining modules if an error is found',
             default: false
      option :amend,
             type: :boolean,
             desc: 'Amend previous commit',
             default: false
      option :force,
             type: :boolean,
             desc: 'Force push amended commit',
             default: false
      option :noop,
             type: :boolean,
             desc: 'No-op mode',
             default: false
      option :pr,
             type: :boolean,
             desc: 'Submit pull/merge request',
             default: false
      option :pr_title,
             desc: 'Title of pull/merge request',
             default: CLI.defaults[:pr_title] || 'Update to module template files'
      option :pr_labels,
             type: :array,
             desc: 'Labels to add to the pull/merge request',
             default: CLI.defaults[:pr_labels] || []
      option :pr_target_branch,
             desc: 'Target branch for the pull/merge request',
             default: CLI.defaults[:pr_target_branch]
      option :offline,
             type: :boolean,
             desc: 'Do not run any Git commands. Allows the user to manage Git outside of ModuleSync.',
             default: false
      option :bump,
             type: :boolean,
             desc: 'Bump module version to the next minor',
             default: false
      option :changelog,
             type: :boolean,
             desc: 'Update CHANGELOG.md if version was bumped',
             default: false
      option :tag,
             type: :boolean,
             desc: 'Git tag with the current module version',
             default: false
      option :tag_pattern,
             desc: 'The pattern to use when tagging releases.'
      option :pre_commit_script,
             desc: 'A script to be run before committing',
             default: CLI.defaults[:pre_commit_script]
      option :fail_on_warnings,
             type: :boolean,
             aliases: '-F',
             desc: 'Produce a failure exit code when there are warnings ' \
                   '(only has effect when --skip_broken is enabled)',
             default: false
      option :branch,
             aliases: '-b',
             desc: 'Branch name to make the changes in. ' \
                   'Defaults to the default branch of the upstream repository, but falls back to "master".',
             default: CLI.defaults[:branch]
      def update
        config = CLI.prepare_options(options)
        raise Thor::Error, 'No value provided for required option "--message"' unless config[:noop] \
                                                                                      || config[:message] \
                                                                                      || config[:offline]

        ModuleSync.update config
      end

      desc 'execute [OPTIONS] -- COMMAND..', 'Execute the command in each managed modules'
      long_desc <<~DESC
        Execute the command in each managed modules.

        COMMAND can be an absolute or a relative path.

        To ease running local commands, a relative path is expanded with the current user directory but only if the target file exists.

        Example: `msync exec custom-scripts/true` will run "$PWD/custom-scripts/true" in each repository.

        As side effect, you can shadow system binary if a local file is present:
        \x5  `msync exec true` will run "$PWD/true", not `/bin/true` if "$PWD/true" exists.
      DESC

      option :configs,
             aliases: '-c',
             desc: 'The local directory or remote repository to define the list of managed modules, ' \
                   'the file templates, and the default values for template variables.'
      option :managed_modules_conf,
             desc: 'The file name to define the list of managed modules'
      option :branch,
             aliases: '-b',
             desc: 'Branch name to make the changes in.',
             default: CLI.defaults[:branch]
      option :default_branch,
             aliases: '-B',
             type: :boolean,
             desc: 'Work on the default branch (take precedence over --branch).',
             default: false
      option :fail_fast,
             type: :boolean,
             desc: 'Abort the run after a command execution failure',
             default: CLI.defaults[:fail_fast].nil? || CLI.defaults[:fail_fast]
      def execute(*command_args)
        raise Thor::Error, 'COMMAND is a required argument' if command_args.empty?

        ModuleSync.execute CLI.prepare_options(options, command_args: command_args)
      end

      desc 'reset', 'Reset local repositories to a well-known state'
      long_desc <<~DESC
        Reset local repository to a well-known state:
        \x5  * Switch local repositories to specified branch
        \x5  * Fetch and prune repositories unless running with `--offline` option
        \x5  * Hard-reset any changes to specified source branch, technically any git refs, e.g. `main`, `origin/wip`
        \x5  * Clean all extra local files

        Note: If a repository is not already cloned, it will operate the following to reach to well-known state:
        \x5  * Clone the repository
        \x5  * Switch to specified branch
      DESC
      option :configs,
             aliases: '-c',
             desc: 'The local directory or remote repository to define the list of managed modules, ' \
                   'the file templates, and the default values for template variables.'
      option :managed_modules_conf,
             desc: 'The file name to define the list of managed modules'
      option :branch,
             aliases: '-b',
             desc: 'Branch name to make the changes in.',
             default: CLI.defaults[:branch]
      option :offline,
             type: :boolean,
             desc: 'Only proceed local operations',
             default: false
      option :source_branch,
             desc: 'Branch to reset from (e.g. origin/wip)'
      def reset
        ModuleSync.reset CLI.prepare_options(options)
      end

      desc 'push', 'Push all available commits from branch to remote'
      option :configs,
             aliases: '-c',
             desc: 'The local directory or remote repository to define the list of managed modules, ' \
                   'the file templates, and the default values for template variables.'
      option :managed_modules_conf,
             desc: 'The file name to define the list of managed modules'
      option :branch,
             aliases: '-b',
             desc: 'Branch name to push',
             default: CLI.defaults[:branch]
      option :remote_branch,
             desc: 'Remote branch to push to (e.g. maintenance)'
      def push
        ModuleSync.push CLI.prepare_options(options)
      end

      desc 'clone', 'Clone repositories that need to'
      def clone
        ModuleSync.clone CLI.prepare_options(options)
      end

      desc 'hook', 'Activate or deactivate a git hook.'
      subcommand 'hook', ModuleSync::CLI::Hook
    end
  end
end
