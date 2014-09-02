require 'git'

module ModuleSync
  module Git
    include Constants

    def self.pull(org, name)
      if ! Dir.exists?(PROJ_ROOT)
        Dir.mkdir(PROJ_ROOT)
      end

      # Repo needs to be cloned in the cwd
      if ! Dir.exists?("#{PROJ_ROOT}/#{name}") || ! Dir.exists?("#{PROJ_ROOT}/#{name}/.git")
        puts "Cloning repository fresh"
        remote = "#{ENDPOINT}:#{org}/#{name}.git"
        local = "#{PROJ_ROOT}/#{name}"
        repo = ::Git.clone(remote, local)

      # Repo already cloned, check out master and override local changes
      else
        puts "Overriding any local changes to repositories in #{PROJ_ROOT}"
        repo = ::Git.open("#{PROJ_ROOT}/#{name}")
        repo.branch('master').checkout
        repo.reset_hard
        repo.pull
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
        repo.push
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
      repo.status.untracked.keep_if{|f,_| !ignored.any?{|i| f.match(/#{i}/)}}
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
