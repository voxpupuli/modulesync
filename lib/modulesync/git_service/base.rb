module ModuleSync
  module GitService
    # Generic class for git services
    class Base
      def open_pull_request(repo_path:, namespace:, title:, message:, source_branch:, target_branch:, labels:, noop:) # rubocop:disable Metrics/ParameterLists, Layout/LineLength
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

      protected

      def _open_pull_request(repo_path:, namespace:, title:, message:, source_branch:, target_branch:, labels:, noop:) # rubocop:disable Metrics/ParameterLists, Metrics/LineLength
        raise NotImplementedError
      end
    end
  end
end
