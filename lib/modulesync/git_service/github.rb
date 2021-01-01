require 'modulesync/git_service'

require 'octokit'
require 'modulesync/util'

module ModuleSync
  module GitService
    # GitHub creates and manages pull requests on github.com or GitHub
    # Enterprise installations.
    class GitHub
      def initialize(token, endpoint)
        Octokit.configure do |c|
          c.api_endpoint = endpoint
        end
        @api = Octokit::Client.new(:access_token => token)
      end

      def open_pull_request(namespace, module_name, options)
        repo_path = File.join(namespace, module_name)
        branch = options[:remote_branch] || options[:branch]
        head = "#{namespace}:#{branch}"
        target_branch = options[:pr_target_branch] || 'master'

        if options[:noop]
          $stdout.puts \
            "Using no-op. Would submit PR '#{options[:pr_title]}' to #{repo_path} " \
            "- merges #{branch} into #{target_branch}"
          return
        end

        pull_requests = @api.pull_requests(repo_path,
                                           :state => 'open',
                                           :base => target_branch,
                                           :head => head)
        unless pull_requests.empty?
          # Skip creating the PR if it exists already.
          $stdout.puts "Skipped! #{pull_requests.length} PRs found for branch #{branch}"
          return
        end

        pr_labels = ModuleSync::Util.parse_list(options[:pr_labels])
        pr = @api.create_pull_request(repo_path,
                                      target_branch,
                                      branch,
                                      options[:pr_title],
                                      options[:message])
        $stdout.puts \
          "Submitted PR '#{options[:pr_title]}' to #{repo_path} " \
          "- merges #{branch} into #{target_branch}"

        # We only assign labels to the PR if we've discovered a list > 1. The labels MUST
        # already exist. We DO NOT create missing labels.
        return if pr_labels.empty?
        $stdout.puts "Attaching the following labels to PR #{pr['number']}: #{pr_labels.join(', ')}"
        @api.add_labels_to_an_issue(repo_path, pr['number'], pr_labels)
      end
    end
  end
end
