module Git
  class Diff
    # Monkey patch process_full_diff until https://github.com/schacon/ruby-git/issues/326 is resolved
    def process_full_diff
      defaults = {
        :mode => '',
        :src => '',
        :dst => '',
        :type => 'modified'
      }
      final = {}
      current_file = nil
      full_diff_utf8_encoded = @full_diff.encode("UTF-8", "binary", {
    :invalid => :replace,
    :undef => :replace
  })
      full_diff_utf8_encoded.split("\n").each do |line|
        if m = /^diff --git a\/(.*?) b\/(.*?)/.match(line)
          current_file = m[1]
          final[current_file] = defaults.merge({:patch => line, :path => current_file})
        elsif !current_file.nil?
          if m = /^index (.......)\.\.(.......)( ......)*/.match(line)
            final[current_file][:src] = m[1]
            final[current_file][:dst] = m[2]
            final[current_file][:mode] = m[3].strip if m[3]
          end
          if m = /^([[:alpha:]]*?) file mode (......)/.match(line)
            final[current_file][:type] = m[1]
            final[current_file][:mode] = m[2]
          end
          if m = /^Binary files /.match(line)
            final[current_file][:binary] = true
          end
          final[current_file][:patch] << "\n" + line
        end
      end
      final.map { |e| [e[0], DiffFile.new(@base, e[1])] }
    end
  end

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
