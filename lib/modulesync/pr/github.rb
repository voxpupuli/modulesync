require 'octokit'
require 'modulesync/util'

module ModuleSync
  module PR
    # GitHub creates and manages pull requests on github.com or GitHub
    # Enterprise installations.
    class GitHub
      def initialize(token, endpoint)
        Octokit.configure do |c|
          c.api_endpoint = endpoint
        end
        @api = Octokit::Client.new(:access_token => token)
      end

      def manage(namespace, module_name, options)
        repo_path = File.join(namespace, module_name)
        head = "#{namespace}:#{options[:branch]}"

        pull_requests = @api.pull_requests(repo_path, :state => 'open', :base => 'master', :head => head)
        if pull_requests.empty?
          pr = @api.create_pull_request(repo_path, 'master', options[:branch], options[:pr_title], options[:message])
          $stdout.puts "Submitted PR '#{options[:pr_title]}' to #{repo_path} - merges #{options[:branch]} into master"
        else
          # Skip creating the PR if it exists already.
          $stdout.puts "Skipped! #{pull_requests.length} PRs found for branch #{options[:branch]}"
        end

        # PR labels can either be a list in the YAML file or they can pass in a comma
        # separated list via the command line argument.
        pr_labels = ModuleSync::Util.parse_list(options[:pr_labels])

        # We only assign labels to the PR if we've discovered a list > 1. The labels MUST
        # already exist. We DO NOT create missing labels.
        return if pr_labels.empty?
        $stdout.puts "Attaching the following labels to PR #{pr['number']}: #{pr_labels.join(', ')}"
        @api.add_labels_to_an_issue(repo_path, pr['number'], pr_labels)
      end
    end
  end
end
