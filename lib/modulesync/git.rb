require 'git'

module ModuleSync
  module Git
    include Constants

    def self.pull(git_user, git_provider_address, org, branch, name)
      if ! Dir.exists?(PROJ_ROOT)
        Dir.mkdir(PROJ_ROOT)
      end

      # Repo needs to be cloned in the cwd
      if ! Dir.exists?("#{PROJ_ROOT}/#{name}") || ! Dir.exists?("#{PROJ_ROOT}/#{name}/.git")
        puts "Cloning repository fresh"
        remote = "#{git_user}@#{git_provider_address}:#{org}/#{name}.git"
        local = "#{PROJ_ROOT}/#{name}"
        puts "Cloning from #{remote}"
        repo = ::Git.clone(remote, local)
        puts "Switching to branch #{branch}"
        repo.checkout(branch)

      # Repo already cloned, check out master and override local changes
      else
        puts "Overriding any local changes to repositories in #{PROJ_ROOT}/#{name}"
        repo = ::Git.open("#{PROJ_ROOT}/#{name}")
        #puts "Switching to branch #{branch}"
        repo.checkout(branch)
        #puts "Resetting working tree to HEAD"
        repo.reset_hard
        puts "Pulling updates from origin/#{branch}"
        repo.pull('origin', branch)
      end
    end

    # Git add/rm, git commit, git push
    def self.update(name, files, message, branch)
      repo = ::Git.open("#{PROJ_ROOT}/#{name}")
      repo.checkout(branch)
      files.each do |file|
        if repo.status.deleted.include?(file)
          repo.remove(file)
        else
          repo.add(file)
        end
      end
      begin
        puts "Pushing commit to origin/#{branch}"
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
