require 'git'
require 'modulesync'

module ModuleSync
  module Git
    class Repo
      attr_accessor :branch, :git_url, :path, :remote_branch, :message,
                    :module_name, :opts, :noop, :mod, :repo

      def initialize(mod, noop, opts)
        @mod = mod
        @noop = noop
        @opts = opts

        @module_name = mod.name
        @branch = mod.project.config['branch']
        @git_url = mod.project.git_url
        @path = mod.path
        @remote_branch = mod.project.config['remote_branch']
        @message = @noop ? 'noop' : mod.project.config['message']

        File.exist?(File.join(path, '.git')) ? pull : clone
      end

      def clone
        remote = opts['remote'] || (git_url.start_with?('file://') ? "#{git_url}/#{module_name}" : "#{git_url}/#{module_name}.git")
        puts "Cloning from #{remote}"
        @repo ||= ::Git.clone(remote, path)
        @repo.checkout "origin/#{branch}"
        @repo.checkout branch
      end

      def pull
        puts "Overriding any local changes to #{path}"
        @repo ||= ::Git.open(path)
        Dir.chdir(path) do
          @repo.fetch
          @repo.reset_hard
          @repo.checkout "origin/#{branch}"
          @repo.checkout branch
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
        puts "Using no-op. Files in #{module_name} will be committed but not pushed."
        changed_output unless changed.to_s.empty?
        added_output unless added.empty?
        deleted_output unless deleted.empty?
        puts "\n\n"
        puts '--------------------------------'
      end

      def commit
        begin
          noop_output if noop

          Dir.chdir(path) do
            repo.remove(deleted.keys) unless deleted.keys.empty?
            repo.add(:all => true)
            repo.commit(message)
            repo.push('origin', branch) unless noop
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
