require 'git'

module ModuleSync
  module Git
    include Constants

    def self.remote_branch_exists?(repo, branch)
      repo.branches.remote.collect { |b| b.name }.include?(branch)
    end

    def self.local_branch_exists?(repo, branch)
      repo.branches.local.collect { |b| b.name }.include?(branch)
    end

    def self.switch_branch(repo, branch)
      unless repo.branch.name == branch
        if local_branch_exists?(repo, branch)
          puts "Switching to branch #{branch}"
          repo.checkout(branch)
        else
          puts "Creating local branch #{branch} from origin/#{branch}"
          repo.checkout("origin/#{branch}")
          repo.branch(branch).checkout
        end
      end
    end

    def self.pull(git_base, name, branch, opts)
      if ! Dir.exists?(PROJ_ROOT)
        Dir.mkdir(PROJ_ROOT)
      end

      # Repo needs to be cloned in the cwd
      if ! Dir.exists?("#{PROJ_ROOT}/#{name}") || ! Dir.exists?("#{PROJ_ROOT}/#{name}/.git")
        puts "Cloning repository fresh"
        remote = opts[:remote] || "#{git_base}/#{name}.git"
        local = "#{PROJ_ROOT}/#{name}"
        puts "Cloning from #{remote}"
        repo = ::Git.clone(remote, local)
        switch_branch(repo, branch)
      # Repo already cloned, check out master and override local changes
      else
        # Some versions of git can't properly handle managing a repo from outside the repo directory
        Dir.chdir("#{PROJ_ROOT}/#{name}") do
          puts "Overriding any local changes to repositories in #{PROJ_ROOT}"
          repo = ::Git.open('.')
          repo.fetch
          repo.reset_hard
          if remote_branch_exists?(repo, branch)
              switch_branch(repo, branch)
              repo.pull('origin', branch)
          else # git checkout -b branch origin/master
            repo.checkout('origin/master')
            puts "Creating new branch #{branch}"
            repo.branch(branch).checkout
          end
        end
      end
    end

    # Git add/rm, git commit, git push
    def self.update(name, files, message, branch)
      repo = ::Git.open("#{PROJ_ROOT}/#{name}")
      repo.branch(branch).checkout
      files.each do |file|
        if repo.status.deleted.include?(file)
          repo.remove(file)
        else
          repo.add(file)
        end
      end
      begin
        repo.commit(message)
        repo.push('origin', branch)
      rescue ::Git::GitExecuteError => git_error
        if git_error.message.include? "nothing to commit, working directory clean"
          puts "There were no files to update in #{name}. Not committing."
        else
          puts git_error
          exit
        end
      end
    end

    # Needed because of a bug in the git gem that lists ignored files as
    # untracked under some circumstances
    # https://github.com/schacon/ruby-git/issues/130
    def self.untracked_unignored_files(repo)
      ignored = File.open("#{repo.dir.path}/.gitignore").read.split
      repo.status.untracked.keep_if{|f,_| !ignored.any?{|i| File.fnmatch(i, f)}}
    end

    def self.update_noop(name, branch)
      puts "Using no-op. Files in #{name} may be changed but will not be committed."

      repo = ::Git.open("#{PROJ_ROOT}/#{name}")
      repo.branch(branch).checkout

      puts "Files changed: "
      repo.diff('HEAD', '--').each do |diff|
        puts diff.patch
      end

      puts "Files added: "
      untracked_unignored_files(repo).each do |file,_|
        puts file
      end

      puts "\n\n"
      puts '--------------------------------'
    end
  end
end
