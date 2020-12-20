module Git
  module LibMonkeyPatch
    # Monkey patch set_custom_git_env_variables due to our ::Git::GitExecuteError handling.
    #
    # We rescue on the GitExecuteError and proceed differently based on the output of git.
    # This way makes code language-dependent, so here we ensure that Git gem throw git commands with the "C" language
    def set_custom_git_env_variables
      super
      ENV['LANG'] = 'C.UTF-8'
    end
  end

  class Lib
    prepend LibMonkeyPatch

    # Monkey patch ls_files until https://github.com/ruby-git/ruby-git/pull/320 is resolved
    def ls_files(location=nil)
      location ||= '.'
      hsh = {}
      command_lines('ls-files', ['--stage', location]).each do |line|
        (info, file) = line.split("\t")
        (mode, sha, stage) = info.split
        file = eval(file) if file =~ /^\".*\"$/ # This takes care of quoted strings returned from git
        hsh[file] = {:path => file, :mode_index => mode, :sha_index => sha, :stage => stage}
      end
      hsh
    end
  end
end
