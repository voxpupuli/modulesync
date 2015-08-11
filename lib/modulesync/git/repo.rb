require 'git'
require 'modulesync'

module ModuleSync
  module Git
    class Repo
      attr_accessor :mod, :noop, :opts, :repo, :git_opts

      def initialize(mod, noop, opts, git_opts)
        @mod = mod
        @noop = noop
        @opts = opts
        @git_opts = git_opts

        File.exist?(File.join(path, '.git')) ? pull : clone
      end

      def url
        return opts['remote'] if opts['remote']
        baseurl = "#{mod.git_base}#{mod.namespace}"
        return "#{baseurl}/#{module_name}" if baseurl.start_with?('file://')
        "#{baseurl}/#{module_name}.git"
      end

      def path
        mod.path
      end

      def module_name
        mod.name
      end

      def branch
        return mod.remote_branch if mod.remote_branch && remote_branches.include?(mod.remote_branch)
        return 'master' unless mod.branch
        return mod.branch
      end

      def message
        @noop ? 'noop' : mod.project_config['message']
      end

      def hooks
        mod.hooks || {}
      end

      def remote_branches
        @remote_branches ||= repo.branches.remote.collect(&:name)
      end

      def checkout
        repo.fetch
        repo.branch(branch).checkout
        repo.reset_hard("origin/#{branch}") rescue ::Git::GitExecuteError
      end

      def clone
        puts "Cloning from #{url}"
        @repo ||= ::Git.clone(url, path)
        Dir.chdir(path) do
          checkout
        end
      end

      def pull
        puts "Overriding any local changes to #{path}"
        @repo ||= ::Git.open(path)
        Dir.chdir(path) do
          checkout
        end
      end

      def deleted
        repo.status.deleted
      end

      def added
        repo.status.untracked
      end

      def changed
        repo.diff('HEAD', '--')
      end

      def changed_output
        puts 'Files changed:'
        puts '=============='
        puts changed
      end

      def added_output
        puts 'Files added:'
        puts '============'
        added.each do |file, _|
          puts file
        end
      end

      def deleted_output
        puts 'Files deleted:'
        puts '=============='
        deleted.each do |file, _|
          puts file
        end
      end

      def noop_output
        puts "Using no-op. Files in #{module_name} will not be committed."
        changed_output unless changed.to_s.empty?
        added_output unless added.empty?
        deleted_output unless deleted.empty?
        puts "\n\n"
        puts '--------------------------------'
      end

      def hook(name)
        return unless hooks[name]
        puts "Running #{name} script #{hooks[name]}"
        `#{hooks[name]} #{path}`
      end

      def commit
        begin
          noop_output if noop

          Dir.chdir(path) do
            repo.remove(deleted.keys) unless deleted.keys.empty?
            repo.add(:all => true)
            hook 'pre_commit'
            repo.commit(message, {:amend => git_opts['amend']}) unless noop
            hook 'pre_push'
            repo.push('origin', branch, {:force => git_opts['force']}) unless noop
          end
        rescue ::Git::GitExecuteError => git_error
          if git_error.message.include? 'nothing to commit, working directory clean'
            puts "There were no files to update in #{module_name}. Not committing."
          else
            puts git_error
            exit 1
          end
        end
      end
    end
  end
end
