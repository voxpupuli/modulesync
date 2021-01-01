module ModuleSync
  # Namespace for Git service classes (ie. GitHub, GitLab)
  module GitService
    def self.instantiate(type:, options:)
      options ||= {}
      case type
      when :github
        endpoint = options[:base_url] || ENV.fetch('GITHUB_BASE_URL', 'https://api.github.com')
        token = options[:token] || ENV['GITHUB_TOKEN']
        raise ModuleSync::Error, 'No GitHub token specified to create a pull request' if token.nil?
        require 'modulesync/git_service/github'
        ModuleSync::GitService::GitHub.new(token, endpoint)
      when :gitlab
        endpoint = options[:base_url] || ENV.fetch('GITLAB_BASE_URL', 'https://gitlab.com/api/v4')
        token = options[:token] || ENV['GITLAB_TOKEN']
        raise ModuleSync::Error, 'No GitLab token specified to create a merge request' if token.nil?
        require 'modulesync/git_service/gitlab'
        ModuleSync::GitService::GitLab.new(token, endpoint)
      else
        raise ModuleSync::Error, "Unable to manage a PR/MR for Git service: '#{type}'"
      end
    end
  end
end
