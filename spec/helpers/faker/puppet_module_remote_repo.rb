require 'open3'

require_relative '../faker'

# Fake a remote git repository that hold a puppet module
#
# This module allow to fake a remote repositiory using:
#  - a bare repo
#  - a temporary cloned repo to operate on the remote before exposition to modulesync
#
# Note: This module need to have working_directory sets before using it
module Faker
  class PuppetModuleRemoteRepo
    attr_reader :name
    attr_reader :namespace

    def initialize(name, namespace)
      @name = name
      @namespace = namespace
    end

    def populate
      FileUtils.chdir(Faker.working_directory) do
        run "git init --bare '#{bare_repo_dir}'"
        run "git clone '#{bare_repo_dir}' '#{tmp_repo_dir}'"

        module_short_name = name.sub(/^puppet-/, '')

        FileUtils.chdir(tmp_repo_dir) do
          metadata = {
            name: "modulesync-#{module_short_name}",
            version: '0.4.2',
            author: 'ModuleSync team',
          }.to_json

          File.write 'metadata.json', metadata
          run 'git add metadata.json'
          run "git commit -m'Initial commit'"
          run 'git push'
        end
      end
    end

    def read_only=(value)
      mode = value ? '0444' : '0644'
      FileUtils.chdir(bare_repo_dir) do
        run "git config core.sharedRepository #{mode}"
      end
    end

    def default_branch=(value)
      FileUtils.chdir(bare_repo_dir) do
        run "git branch -M master #{value}"
        run "git symbolic-ref HEAD refs/heads/#{value}"
      end
    end

    def read_file(filename, branch = nil)
      FileUtils.chdir(tmp_repo_dir) do
        run "git fetch"
        run "git checkout #{branch}" unless branch.nil?
        run "git merge --ff-only"
        return unless File.exists?(filename)

        return File.read filename
      end
    end

    def add_file(filename, content, branch = nil)
      FileUtils.chdir(tmp_repo_dir) do
        run "git checkout #{branch}" unless branch.nil?
        File.write filename, content
        run "git add #{filename}"
        run "git commit -m'Add file: \"#{filename}\"'"
        run 'git push'
      end
    end

    def commit_count_between(commit1, commit2)
      FileUtils.chdir(bare_repo_dir) do
        stdout = run "git rev-list --count #{commit1}..#{commit2}"
        return Integer(stdout)
      end
    end

    def commit_count_by(author, commit = nil)
      FileUtils.chdir(bare_repo_dir) do
        commit ||= '--all'
        stdout = run "git rev-list #{commit} --author='#{author}' --count"
        return Integer(stdout)
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
      "#{Faker.working_directory}/tmp/#{namespace}/#{name}"
    end

    def bare_repo_dir
      "#{Faker.working_directory}/bare/#{namespace}/#{name}.git"
    end

    GIT_ENV = {
        'GIT_AUTHOR_NAME' => 'Faker',
        'GIT_AUTHOR_EMAIL' => 'faker@example.com',
        'GIT_COMMITTER_NAME' => 'Faker',
        'GIT_COMMITTER_EMAIL' => 'faker@example.com',
      }

    def run(command)
      stdout, stderr, status = Open3.capture3(GIT_ENV, command)
      return stdout if status.success?

      $stderr.puts "Command '#{command}' failed: #{status}"
      $stderr.puts '  STDOUT:'
      $stderr.puts stdout
      $stderr.puts '  STDERR:'
      $stderr.puts stderr
      raise
    end
  end
end
