require 'modulesync/git_service'
require 'modulesync/git_service/base'

require 'octokit'
require 'modulesync/util'

module ModuleSync
  module GitService
    # GitHub creates and manages pull requests on github.com or GitHub
    # Enterprise installations.
    class GitHub < Base
      def initialize(token, endpoint)
        Octokit.configure do |c|
          c.api_endpoint = endpoint
        end
        @api = Octokit::Client.new(:access_token => token)
      end

      private

      def _open_pull_request(repo_path:, namespace:, title:, message:, source_branch:, target_branch:, labels:, noop:) # rubocop:disable Metrics/ParameterLists, Metrics/LineLength
        head = "#{namespace}:#{source_branch}"

        if noop
          $stdout.puts \
            "Using no-op. Would submit PR '#{title}' to '#{repo_path}' " \
            "- merges '#{source_branch}' into '#{target_branch}'"
          return
        end

        pull_requests = @api.pull_requests(repo_path,
                                           :state => 'open',
                                           :base => target_branch,
                                           :head => head)
        unless pull_requests.empty?
          # Skip creating the PR if it exists already.
          $stdout.puts "Skipped! #{pull_requests.length} PRs found for branch '#{source_branch}'"
          return
        end

        pr = @api.create_pull_request(repo_path,
                                      target_branch,
                                      source_branch,
                                      title,
                                      message)
        $stdout.puts \
          "Submitted PR '#{title}' to '#{repo_path}' " \
          "- merges #{source_branch} into #{target_branch}"

        # We only assign labels to the PR if we've discovered a list > 1. The labels MUST
        # already exist. We DO NOT create missing labels.
        return if labels.empty?
        $stdout.puts "Attaching the following labels to PR #{pr['number']}: #{labels.join(', ')}"
        @api.add_labels_to_an_issue(repo_path, pr['number'], labels)
      end
    end
  end
end
