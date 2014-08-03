require 'optparse'

module ModuleSync
  class CLI

    def defaults
      {
        :namespace            => 'puppetlabs',
        :branch               => 'master',
        :managed_modules_conf => 'managed_modules.yml',
      }
    end

    def fail(message)
      puts @options[:help]
      puts message
      exit
    end

    def parse_opts(args)
      @options = defaults
      opt_parser = OptionParser.new do |opts|
        opts.banner = "Usage: sync.rb -m <commit message> [--noop]"
        opts.on('-m', '--message <msg>',
                'Commit message to apply to updated modules') do |msg|
          @options[:message] = msg
        end
        opts.on('-n', '--namespace <url>',
                'Remote github namespace to clone from and push to. Defaults to git@github.com:puppetlabs') do |namespace|
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
        opts.on('--noop',
                'No-op mode') do |msg|
          @options[:noop] = true
        end
        @options[:help] = opts.help
      end.parse!

      @options.fetch(:message) do
        if ! @options[:noop]
          fail("A commit message is required.")
        end
      end

      @options.fetch(:configs) do
        fail("The configs directory is required.")
      end
    end

    def options
      @options
    end
  end
end
