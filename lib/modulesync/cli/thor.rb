# frozen_string_literal: true

require 'thor'
require 'modulesync/cli'

module ModuleSync
  module CLI
    # Workaround some, still unfixed, Thor behaviors
    #
    # This class extends ::Thor class to
    # - exit with status code sets to `1` on Thor failure (e.g. missing required option)
    # - exit with status code sets to `1` when user calls `msync` (or a subcommand) without required arguments
    # - show subcommands help using `msync subcommand --help`
    class Thor < ::Thor
      def self.start(*args)
        if Thor::HELP_MAPPINGS.intersect?(ARGV) && subcommands.none? { |command| command.start_with?(ARGV[0]) }
          Thor::HELP_MAPPINGS.each do |cmd|
            if (match = ARGV.delete(cmd))
              ARGV.unshift match
            end
          end
        end
        super
      end

      desc '_invalid_command_call', 'Invalid command', hide: true
      def _invalid_command_call
        self.class.new.help
        exit 1
      end
      default_task :_invalid_command_call

      def self.exit_on_failure?
        true
      end
    end
  end
end
