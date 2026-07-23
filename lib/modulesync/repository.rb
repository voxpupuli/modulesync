# frozen_string_literal: true

require 'git'

module ModuleSync
  # Wrapper for Git in ModuleSync context
  class Repository
    def initialize(directory:, remote:)
      @directory = directory
      @remote = remote
    end

    def git
      @git ||= Git.open @directory
    end

    # This is an alias to minimize code alteration
    def repo
      git
    end

    def remote_branch_exists?(branch)
      repo.branches.remote.collect(&:name).include?(branch)
    end

    def local_branch_exists?(branch)
      repo.branches.local.collect(&:name).include?(branch)
    end

    def remote_branch_differ?(local_branch, remote_branch)
      !remote_branch_exists?(remote_branch) ||
        repo.diff("#{local_branch}..origin/#{remote_branch}").any?
    end

    # This method checks if the source branch is ahead of the target branch in the remote repository.
    # It does this by checking if there are any commits in the source branch that are not in the target branch.
    def remote_branch_ahead?(source_branch, target_branch)
      return false unless remote_branch_exists?(source_branch) && remote_branch_exists?(target_branch)

      log = repo.log(1).between("origin/#{target_branch}", "origin/#{source_branch}")
      commits = log.respond_to?(:execute) ? log.execute : log
      commits.any?
    end

    def branch_behind?(branch, target_branch)
      log = repo.log(1).between(branch, "origin/#{target_branch}")
      commits = log.respond_to?(:execute) ? log.execute : log
      commits.any?
    end

    def default_branch
      # `Git.default_branch` requires ruby-git >= 1.17.0
      return Git.default_branch(repo.dir) if Git.respond_to? :default_branch

      symbolic_ref = repo.branches.find { |b| b.full.include?('remotes/origin/HEAD') }
      return unless symbolic_ref

      %r{remotes/origin/HEAD\s+->\s+origin/(?<branch>.+?)$}.match(symbolic_ref.full)[:branch]
    end

    def remote_default_branch
      return Git.default_branch(@remote) if Git.respond_to? :default_branch

      default_branch
    end

    def switch(branch:)
      unless branch
        branch = default_branch
        puts "Using repository's default branch: #{branch}"
      end
      return if repo.current_branch == branch

      if local_branch_exists?(branch)
        puts "Switching to branch #{branch}"
        repo.checkout(branch)
      elsif remote_branch_exists?(branch)
        puts "Creating local branch #{branch} from origin/#{branch}"
        repo.checkout("origin/#{branch}")
        repo.branch(branch).checkout
      else
        base_branch = default_branch
        unless base_branch
          puts "Couldn't detect default branch. Falling back to assuming 'master'"
          base_branch = 'master'
        end
        puts "Creating new branch #{branch} from #{base_branch}"
        repo.checkout("origin/#{base_branch}")
        repo.branch(branch).checkout
      end
    end

    def cloned?
      Dir.exist? File.join(@directory, '.git')
    end

    def clone
      puts "Cloning from '#{@remote}'"
      @git = Git.clone(@remote, @directory)
    end

    def prepare_workspace(branch:, operate_offline:, rebase: false)
      @rebased = false
      if cloned?
        puts "Overriding any local changes to repository in '#{@directory}'"
        git.fetch 'origin', prune: true unless operate_offline
        git.reset_hard
        rebase_target = remote_default_branch if rebase && !operate_offline
        switch(branch: branch)
        git.pull('origin', branch) if !operate_offline && remote_branch_exists?(branch)
        rebase_onto(rebase_target) if rebase_target
      else
        raise ModuleSync::Error, 'Unable to clone in offline mode.' if operate_offline

        clone
        switch(branch: branch)
      end
    end

    def rebase_onto(branch)
      return false if repo.current_branch == branch || !branch_behind?(repo.current_branch, branch)

      puts "Rebasing #{repo.current_branch} onto origin/#{branch}"
      repo.lib.send(:command, 'rebase', "origin/#{branch}")
      @rebased = true
    rescue Git::Error => e
      begin
        repo.lib.send(:command, 'rebase', '--abort')
      rescue Git::Error
        # Preserve the original rebase error if Git had no rebase to abort.
      end
      raise ModuleSync::Error, "Rebase onto origin/#{branch} failed and was aborted: #{e.message}"
    end

    def push_changes(branch, remote_branch, options)
      refspec = remote_branch ? "#{branch}:#{remote_branch}" : branch
      if @rebased && !options[:force]
        repo.lib.send(:command, 'push', '--force-with-lease', 'origin', refspec)
      else
        opts_push = options[:force] ? { force: true } : {}
        repo.push('origin', refspec, opts_push)
      end
    end

    def default_reset_branch(branch)
      remote_branch_exists?(branch) ? branch : default_branch
    end

    def reset_workspace(branch:, operate_offline:, source_branch: nil)
      raise if branch.nil?

      if cloned?
        source_branch ||= "origin/#{default_reset_branch branch}"
        puts "Hard-resetting any local changes to repository in '#{@directory}' from branch '#{source_branch}'"
        switch(branch: branch)
        git.fetch 'origin', prune: true unless operate_offline

        git.reset_hard source_branch
        git.clean(d: true, force: true)
      else
        raise ModuleSync::Error, 'Unable to clone in offline mode.' if operate_offline

        clone
        switch(branch: branch)
      end
    end

    def tag(version, tag_pattern, sign: false)
      tag = tag_pattern % version
      puts "Tagging with #{tag}"
      repo.add_tag(tag, sign: sign)
      repo.push('origin', tag)
    end

    def checkout_branch(branch)
      selected_branch = branch || repo.current_branch || 'master'
      repo.branch(selected_branch).checkout
      selected_branch
    end

    def commit_changes(message, options)
      commit_options = {}
      commit_options[:amend] = true if options[:amend]
      commit_options[:gpg_sign] = true if options[:sign]
      return repo.commit(message, commit_options) unless options[:signoff]

      arguments = ["--message=#{message}"]
      arguments.push('--amend', '--no-edit') if options[:amend]
      arguments << '--gpg-sign' if options[:sign]
      arguments << '--signoff'
      repo.lib.send(:command, 'commit', *arguments)
    end

    # Git add/rm, git commit, git push
    def submit_changes(files, options)
      message = options[:message]
      branch = checkout_branch(options[:branch])
      files.each do |file|
        if repo.status.deleted.include?(file)
          repo.remove(file)
        elsif File.exist? File.join(@directory, file)
          repo.add(file)
        end
      end
      begin
        if options[:pre_commit_script]
          script = "#{File.dirname(__FILE__, 3)}/contrib/#{options[:pre_commit_script]}"
          system(script, @directory)
        end
        if repo.status.changed.empty? && repo.status.added.empty? && repo.status.deleted.empty?
          puts "There were no changes in '#{@directory}'. Not committing."
          return false unless @rebased
        else
          commit_changes(message, options)
        end
        if options[:remote_branch]
          if @rebased || remote_branch_differ?(branch, options[:remote_branch])
            push_changes(branch, options[:remote_branch], options)
            puts "Changes have been pushed to: '#{branch}:#{options[:remote_branch]}'"
          end
        else
          push_changes(branch, nil, options)
          puts "Changes have been pushed to: '#{branch}'"
        end
      rescue Git::Error => e
        raise e.message
      end

      true
    end

    def push(branch:, remote_branch:, remote_name: 'origin')
      raise ModuleSync::Error, 'Repository must be locally available before trying to push' unless cloned?

      remote_url = git.remote(remote_name).url
      remote_branch ||= branch
      puts "Push branch '#{branch}' to '#{remote_url}' (#{remote_name}/#{remote_branch})"

      git.push(remote_name, "#{branch}:#{remote_branch}", force: true)
    end

    # Needed because of a bug in the git gem that lists ignored files as
    # untracked under some circumstances
    # https://github.com/schacon/ruby-git/issues/130
    def untracked_unignored_files
      ignore_path = File.join @directory, '.gitignore'
      ignored = File.exist?(ignore_path) ? File.read(ignore_path).split : []
      repo.status.untracked.keep_if { |f, _| ignored.none? { |i| File.fnmatch(i, f) } }
    end

    def show_changes(options)
      checkout_branch(options[:branch])

      $stdout.puts 'Files changed:'
      repo.diff('HEAD').each do |diff|
        $stdout.puts diff.patch
      end

      $stdout.puts 'Files added:'
      untracked_unignored_files.each_key do |file|
        $stdout.puts file
      end

      $stdout.puts "\n\n"
      $stdout.puts '--------------------------------'

      git.diff('HEAD').any? || untracked_unignored_files.any?
    end

    def puts(*)
      $stdout.puts(*) if ModuleSync.options[:verbose]
    end
  end
end
