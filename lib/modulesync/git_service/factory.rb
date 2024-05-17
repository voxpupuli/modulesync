# frozen_string_literal: true

module ModuleSync
  module GitService
    # Git service's factory
    module Factory
      def self.instantiate(type:, endpoint:, token:)
        raise MissingCredentialsError, <<~MESSAGE if token.nil?
          A token is required to use services from #{type}:
            Please set environment variable: "#{type.upcase}_TOKEN" or set the token entry in module options.
        MESSAGE

        klass(type: type).new token, endpoint
      end

      def self.klass(type:)
        case type
        when :github
          require 'modulesync/git_service/github'
          ModuleSync::GitService::GitHub
        when :gitlab
          require 'modulesync/git_service/gitlab'
          ModuleSync::GitService::GitLab
        else
          raise NotImplementedError, "Unknown git service: '#{type}'"
        end
      end
    end
  end
end
