require 'thor'
require 'modulesync/cli'

module ModuleSync
  module CLI
    # Workaround some, still unfixed, Thor behaviors
    #
    # This class extends ::Thor class to
    # - exit with status code sets to `1` on Thor failure (e.g. missing required option)
    # - exit with status code sets to `1` when user calls `msync` (or a subcommand) without required arguments
    class Thor < ::Thor
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
