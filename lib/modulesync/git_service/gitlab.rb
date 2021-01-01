require 'modulesync/git_service'

require 'gitlab'
require 'modulesync/util'

module ModuleSync
  module GitService
    # GitLab creates and manages merge requests on gitlab.com or private GitLab
    # installations.
    class GitLab
      def initialize(token, endpoint)
        @api = Gitlab::Client.new(
          :endpoint => endpoint,
          :private_token => token
        )
      end

      def open_pull_request(namespace, module_name, options)
        repo_path = File.join(namespace, module_name)
        branch = options[:remote_branch] || options[:branch]
        head = "#{namespace}:#{branch}"
        target_branch = options[:pr_target_branch] || 'master'

        if options[:noop]
          $stdout.puts \
            "Using no-op. Would submit MR '#{options[:pr_title]}' to #{repo_path} " \
            "- merges #{branch} into #{target_branch}"
          return
        end

        merge_requests = @api.merge_requests(repo_path,
                                             :state => 'opened',
                                             :source_branch => head,
                                             :target_branch => target_branch)
        unless merge_requests.empty?
          # Skip creating the MR if it exists already.
          $stdout.puts "Skipped! #{merge_requests.length} MRs found for branch #{branch}"
          return
        end

        mr_labels = ModuleSync::Util.parse_list(options[:pr_labels])
        mr = @api.create_merge_request(repo_path,
                                       options[:pr_title],
                                       :source_branch => branch,
                                       :target_branch => target_branch,
                                       :labels => mr_labels)
        $stdout.puts \
          "Submitted MR '#{options[:pr_title]}' to #{repo_path} " \
          "- merges #{branch} into #{target_branch}"

        return if mr_labels.empty?
        $stdout.puts "Attached the following labels to MR #{mr.iid}: #{mr_labels.join(', ')}"
      end
    end
  end
end
