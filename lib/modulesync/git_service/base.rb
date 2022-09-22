module ModuleSync
  module GitService
    # Generic class for git services
    class Base
      def open_pull_request(repo_path:, namespace:, title:, message:, source_branch:, target_branch:, labels:, noop:) # rubocop:disable Metrics/ParameterLists
        unless source_branch != target_branch
          raise ModuleSync::Error,
                "Unable to open a pull request with the same source and target branch: '#{source_branch}'"
        end

        _open_pull_request(
          repo_path: repo_path,
          namespace: namespace,
          title: title,
          message: message,
          source_branch: source_branch,
          target_branch: target_branch,
          labels: labels,
          noop: noop,
        )
      end

      # This method attempts to guess the git service endpoint based on remote
      def self.guess_endpoint_from(remote:)
        hostname = extract_hostname(remote)
        return nil if hostname.nil?

        "https://#{hostname}"
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
        return nil if url.start_with?('/', 'file://') # local path (e.g. file:///path/to/repo)

        unless url.start_with?(%r{[a-z]+://}) # SSH notation does not contain protocol (e.g. user@server:path/to/repo/)
          pattern = /^(?<user>.*@)?(?<hostname>[\w|.]*):(?<repo>.*)$/ # SSH path (e.g. user@server:repo)
          return url.match(pattern)[:hostname] if url.match?(pattern)
        end

        URI.parse(url).host
      rescue URI::InvalidURIError
        nil
      end

      protected

      def _open_pull_request(repo_path:, namespace:, title:, message:, source_branch:, target_branch:, labels:, noop:) # rubocop:disable Metrics/ParameterLists
        raise NotImplementedError
      end
    end
  end
end
