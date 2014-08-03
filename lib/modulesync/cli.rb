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
        opts.on('-c', '--managedmodules <file>',
                'Config file to list modules to manage.
                                         Defaults to "managed_modules.yml" which lists the Puppet Labs supported modules.') do |file|
          @options[:managed_modules_conf] = file
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
          puts @options[:help]
          puts "A commit message is required."
          exit
        end
      end
    end

    def options
      @options
    end
  end
end
