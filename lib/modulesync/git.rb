require 'git'
require 'puppet_blacksmith'

module ModuleSync
  module Git
    include Constants

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

      # Repo already cloned, check out master and override local changes
      else
        puts "Overriding any local changes to repositories in #{PROJ_ROOT}"
        repo = ::Git.open("#{PROJ_ROOT}/#{name}")
        repo.branch(branch).checkout
        repo.reset_hard
        repo.pull('origin', branch)
      end
    end

    def self.bump(repo, m)
      new = m.bump!
      puts "Bumped to version #{new}"
      repo.add('metadata.json')
      repo.commit("Release version #{new}")
      repo.push
      new
    end

    def self.tag(repo, version, tag_pattern)
      tag = tag_pattern % version
      puts "Tagging with #{tag}"
      repo.add_tag(tag)
      repo.push('origin', tag)
    end

    # Git add/rm, git commit, git push
    def self.update(name, files, message, branch, bump=false, tag=false, tag_pattern=nil)
      module_root = "#{PROJ_ROOT}/#{name}"
      repo = ::Git.open(module_root)
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
        # Only bump/tag if pushing didn't fail (i.e. there were changes)
        m = Blacksmith::Modulefile.new("#{module_root}/metadata.json")
        if bump
          new = self.bump(repo, m)
          self.tag(repo, new, tag_pattern) if tag
        end
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
