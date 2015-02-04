require 'optparse'
require 'modulesync/constants'
require 'modulesync/util'

module ModuleSync
  class CLI
    include Constants

    def defaults
      {
        :namespace            => 'puppetlabs',
        :branch               => 'master',
        :git_user             => 'git',
        :git_provider_address => 'github.com',
        :managed_modules_conf => 'managed_modules.yml',
        :configs              => '.',
        :tag_pattern          => '%s',
      }
    end

    def commands_available
      [
        'update',
        'hook',
      ]
    end

    def fail(message)
      puts @options[:help]
      puts message
      exit
    end

    def parse_opts(args)
      @options = defaults
      @options.merge!(Hash.transform_keys_to_symbols(Util.parse_config(MODULESYNC_CONF_FILE)))
      @options[:command] = args[0] if commands_available.include?(args[0])
      opt_parser = OptionParser.new do |opts|
        opts.banner = "Usage: msync update [-m <commit message>] [-c <directory> ] [--noop] [--bump] [--tag] [--tag-pattern <tag_pattern>] [-n <namespace>] [-b <branch>] [-f <filter>] | hook activate|deactivate [-c <directory> ] [-n <namespace>] [-b <branch>]"
        opts.on('-m', '--message <msg>',
                'Commit message to apply to updated modules') do |msg|
          @options[:message] = msg
        end
        opts.on('-n', '--namespace <url>',
                'Remote github namespace (user or organization) to clone from and push to. Defaults to puppetlabs') do |namespace|
          @options[:namespace] = namespace
        end
        opts.on('-c', '--configs <directory>',
                'The local directory or remote repository to define the list of managed modules, the file templates, and the default values for template variables.') do |configs|
          @options[:configs] = configs
        end
        opts.on('-b', '--branch <branch>',
                'Branch name to make the changes in. Defaults to "master"') do |branch|
          @options[:branch] = branch
        end
        opts.on('-f', '--filter <filter>',
                'A regular expression to filter repositories to update.') do |filter|
          @options[:filter] = filter
        end
        opts.on('--noop',
                'No-op mode') do |msg|
          @options[:noop] = true
        end
        opts.on('--bump',
                'Bump module version to the next minor') do |msg|
          @options[:bump] = true
        end
        opts.on('--tag',
                'Git tag with the current module version') do |msg|
          @options[:tag] = true
        end
        opts.on('--tag-pattern',
                'The pattern to use when tagging releases.') do |pattern|
          @options[:tag_pattern] = pattern
        end
        @options[:help] = opts.help
      end.parse!

      @options.fetch(:message) do
        if @options[:command] == 'update' && ! @options[:noop]
          fail("A commit message is required unless using noop.")
        end
      end

      @options.fetch(:command) do
        fail("A command is required.")
      end

      if @options[:command] == 'hook' &&
           (! args.include?('activate') && ! args.include?('deactivate'))
        fail("You must activate or deactivate the hook.")
      end

    end

    def options
      @options
    end
  end
end
