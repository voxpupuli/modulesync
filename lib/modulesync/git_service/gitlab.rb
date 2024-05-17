# frozen_string_literal: true

require 'gitlab'
require 'modulesync/git_service'
require 'modulesync/git_service/base'

module ModuleSync
  module GitService
    # GitLab creates and manages merge requests on gitlab.com or private GitLab
    # installations.
    class GitLab < Base
      def initialize(token, endpoint)
        super()

        @api = Gitlab::Client.new(
          endpoint: endpoint,
          private_token: token,
        )
      end

      def self.guess_endpoint_from(remote:)
        endpoint = super
        return nil if endpoint.nil?

        endpoint += '/api/v4'
        endpoint
      end

      private

      def _open_pull_request(repo_path:, namespace:, title:, message:, source_branch:, target_branch:, labels:, noop:) # rubocop:disable Lint/UnusedMethodArgument
        if noop
          $stdout.puts "Using no-op. Would submit MR '#{title}' to '#{repo_path}' " \
                       "- merges #{source_branch} into #{target_branch}"
          return
        end

        merge_requests = @api.merge_requests(repo_path,
                                             state: 'opened',
                                             source_branch: source_branch,
                                             target_branch: target_branch)
        unless merge_requests.empty?
          # Skip creating the MR if it exists already.
          $stdout.puts "Skipped! #{merge_requests.length} MRs found for branch '#{source_branch}'"
          return
        end

        mr = @api.create_merge_request(repo_path,
                                       title,
                                       source_branch: source_branch,
                                       target_branch: target_branch,
                                       labels: labels)
        $stdout.puts \
          "Submitted MR '#{title}' to '#{repo_path}' " \
          "- merges '#{source_branch}' into '#{target_branch}'"

        return if labels.empty?

        $stdout.puts "Attached the following labels to MR #{mr.iid}: #{labels.join(', ')}"
      end
    end
  end
end
