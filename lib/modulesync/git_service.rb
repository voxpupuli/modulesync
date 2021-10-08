module ModuleSync
  class Error < StandardError; end

  # Namespace for Git service classes (ie. GitHub, GitLab)
  module GitService
    class MissingCredentialsError < Error; end

    def self.configuration_for(sourcecode:)
      type = type_for(sourcecode: sourcecode)

      {
        type: type,
        endpoint: endpoint_for(sourcecode: sourcecode, type: type),
        token: token_for(sourcecode: sourcecode, type: type),
      }
    end

    # This method attempts to guess git service's type (ie. gitlab or github)
    # It process in this order
    #   1. use module specific configuration entry (ie. a specific entry named `gitlab` or `github`)
    #   2. guess using remote url (ie. looking for `github` or `gitlab` string)
    #   3. use environment variables (ie. check if GITHUB_TOKEN or GITLAB_TOKEN is set)
    #   4. fail
    def self.type_for(sourcecode:)
      return :github unless sourcecode.options[:github].nil?
      return :gitlab unless sourcecode.options[:gitlab].nil?
      return :github if sourcecode.repository_remote.include? 'github'
      return :gitlab if sourcecode.repository_remote.include? 'gitlab'

      if ENV['GITLAB_TOKEN'].nil? && ENV['GITHUB_TOKEN'].nil?
        raise ModuleSync::Error, <<~MESSAGE
          Unable to guess Git service type without GITLAB_TOKEN or GITHUB_TOKEN sets.
        MESSAGE
      end

      unless ENV['GITLAB_TOKEN'].nil? || ENV['GITHUB_TOKEN'].nil?
        raise ModuleSync::Error, <<~MESSAGE
          Unable to guess Git service type with both GITLAB_TOKEN and GITHUB_TOKEN sets.

          Please set the wanted one in configuration (ie. add `gitlab:` or `github:` key)
        MESSAGE
      end

      return :github unless ENV['GITHUB_TOKEN'].nil?
      return :gitlab unless ENV['GITLAB_TOKEN'].nil?

      raise NotImplementedError
    end

    # This method attempts to find git service's endpoint based on sourcecode and type
    # It process in this order
    #   1. use module specific configuration (ie. `base_url`)
    #   2. use environment variable dependending on type (e.g. GITLAB_BASE_URL)
    #   3. guess using the git remote url
    #   4. fail
    def self.endpoint_for(sourcecode:, type:)
      endpoint = sourcecode.options.dig(type, :base_url)

      endpoint ||= case type
                   when :github
                     ENV['GITHUB_BASE_URL']
                   when :gitlab
                     ENV['GITLAB_BASE_URL']
                   end

      endpoint ||= guess_endpoint_from(remote: sourcecode.repository_remote, type: type)

      raise NotImplementedError, <<~MESSAGE if endpoint.nil?
        Unable to guess endpoint for remote: '#{sourcecode.repository_remote}'
        Please provide `base_url` option in configuration file
      MESSAGE

      endpoint
    end

    # This method attempts to guess the git service endpoint based on remote and type
    def self.guess_endpoint_from(remote:, type:)
      hostname = extract_hostname(remote)
      return nil if hostname.nil?

      endpoint = "https://#{hostname}"
      endpoint += '/api/v4' if type == :gitlab
      endpoint
    end

    # This method attempts to find the token associated to provided sourcecode and type
    # It process in this order:
    #   1. use module specific configuration (ie. `token`)
    #   2. use environment variable depending on type (e.g. GITLAB_TOKEN)
    #   3. fail
    def self.token_for(sourcecode:, type:)
      token = sourcecode.options.dig(type, :token)

      token ||= case type
                when :github
                  ENV['GITHUB_TOKEN']
                when :gitlab
                  ENV['GITLAB_TOKEN']
                end

      token
    end

    # This method extracts hostname from URL like:
    #
    # - ssh://[user@]host.xz[:port]/path/to/repo.git/
    # - git://host.xz[:port]/path/to/repo.git/
    # - [user@]host.xz:path/to/repo.git/
    # - http[s]://host.xz[:port]/path/to/repo.git/
    # - ftp[s]://host.xz[:port]/path/to/repo.git/
    #
    # Returns nil if
    # - /path/to/repo.git/
    # - file:///path/to/repo.git/
    # - any invalid URL
    def self.extract_hostname(url)
      return nil if url.start_with?('/') || url.start_with?('file://') # local path (e.g. file:///path/to/repo)

      unless url.start_with?(/[a-z]+:\/\//) # SSH notation does not contain protocol (e.g. user@server:path/to/repo/)
        pattern = /^(.*@)?(?<hostname>[\w|.]*):(.*)$/ # SSH path (e.g. user@server:repo)
        return url.match(pattern)[:hostname] if url.match?(pattern)
      end

      URI.parse(url).host
    rescue URI::InvalidURIError
      nil
    end
  end
end
