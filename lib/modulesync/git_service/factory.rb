module ModuleSync
  module GitService
    # Git service's factory
    module Factory
      def self.instantiate(type:, endpoint:, token:)
        raise MissingCredentialsError, <<~MESSAGE if token.nil?
          A token is required to use services from #{type}:
            Please set environment variable: "#{type.upcase}_TOKEN" or set the token entry in module options.
        MESSAGE

        case type
        when :github
          require 'modulesync/git_service/github'
          ModuleSync::GitService::GitHub.new(token, endpoint)
        when :gitlab
          require 'modulesync/git_service/gitlab'
          ModuleSync::GitService::GitLab.new(token, endpoint)
        else
          raise NotImplementedError, "Unable to manage a PR/MR for Git service: '#{type}'"
        end
      end
    end
  end
end
