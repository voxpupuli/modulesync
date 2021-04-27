require 'open3'

require_relative '../faker'

module ModuleSync
  # Fake a remote git repository that holds a puppet module
  #
  # This module allows to fake a remote repositiory using:
  #  - a bare repo
  #  - a temporary cloned repo to operate on the remote before exposing to modulesync
  #
  # Note: This module needs to have working_directory sets before using it
  module Faker
    class PuppetModuleRemoteRepo
      class CommandExecutionError < StandardError; end

      attr_reader :name, :namespace

      def initialize(name, namespace)
        @name = name
        @namespace = namespace
      end

      def populate
        FileUtils.chdir(Faker.working_directory) do
          run %W[git init --bare #{bare_repo_dir}]
          run %W[git clone #{bare_repo_dir} #{tmp_repo_dir}]

          module_short_name = name.split('-').last

          FileUtils.chdir(tmp_repo_dir) do
            metadata = {
              name: "modulesync-#{module_short_name}",
              version: '0.4.2',
              author: 'ModuleSync team',
            }

            File.write 'metadata.json', metadata.to_json
            run %w[git add metadata.json]
            run %w[git commit --message] << 'Initial commit'
            run %w[git push]
          end
        end
      end

      def read_only=(value)
        mode = value ? '0444' : '0644'
        FileUtils.chdir(bare_repo_dir) do
          run %W[git config core.sharedRepository #{mode}]
        end
      end

      def default_branch
        FileUtils.chdir(bare_repo_dir) do
          stdout = run %w[git symbolic-ref --short HEAD]
          return stdout.chomp
        end
      end

      def default_branch=(value)
        FileUtils.chdir(bare_repo_dir) do
          run %W[git branch -M #{default_branch} #{value}]
          run %W[git symbolic-ref HEAD refs/heads/#{value}]
        end
      end

      def read_file(filename, branch = nil)
        branch ||= default_branch
        FileUtils.chdir(bare_repo_dir) do
          return run %W[git show #{branch}:#{filename}]
        rescue CommandExecutionError
          return nil
        end
      end

      def add_file(filename, content, branch = nil)
        branch ||= default_branch
        FileUtils.chdir(tmp_repo_dir) do
          run %W[git checkout #{branch}]
          File.write filename, content
          run %W[git add #{filename}]
          run %w[git commit --message] << "Add file: '#{filename}'"
          run %w[git push]
        end
      end

      def commit_count_between(commit1, commit2)
        FileUtils.chdir(bare_repo_dir) do
          stdout = run %W[git rev-list --count #{commit1}..#{commit2}]
          return Integer(stdout)
        end
      end

      def commit_count_by(author, commit = nil)
        FileUtils.chdir(bare_repo_dir) do
          commit ||= '--all'
          stdout = run %W[git rev-list #{commit} --author #{author} --count]
          return Integer(stdout)
        end
      end

      def tags
        FileUtils.chdir(bare_repo_dir) do
          return run %w{git tag --list}
        end
      end

      def delete_branch(branch)
        FileUtils.chdir(bare_repo_dir) do
          run %W{git branch -D #{branch}}
        end
      end

      def create_branch(branch, from = nil)
        from ||= default_branch
        FileUtils.chdir(tmp_repo_dir) do
          run %W{git branch -c #{from} #{branch}}
          run %W{git push --set-upstream origin #{branch}}
        end
      end

      def remote_url
        "file://#{bare_repo_dir}"
      end

      def self.git_base
        "file://#{Faker.working_directory}/bare/"
      end

      private

      def tmp_repo_dir
        File.join Faker.working_directory, 'tmp', namespace, name
      end

      def bare_repo_dir
        File.join Faker.working_directory, 'bare', namespace, "#{name}.git"
      end

      GIT_ENV = {
        'GIT_AUTHOR_NAME' => 'Faker',
        'GIT_AUTHOR_EMAIL' => 'faker@example.com',
        'GIT_COMMITTER_NAME' => 'Faker',
        'GIT_COMMITTER_EMAIL' => 'faker@example.com',
      }.freeze

      def run(command)
        stdout, stderr, status = Open3.capture3(GIT_ENV, *command)
        return stdout if status.success?

        warn "Command '#{command}' failed: #{status}"
        warn '  STDOUT:'
        warn stdout
        warn '  STDERR:'
        warn stderr
        raise CommandExecutionError, "Command '#{command}' failed: #{status}"
      end
    end
  end
end
