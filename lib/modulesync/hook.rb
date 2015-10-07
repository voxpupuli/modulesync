module ModuleSync
  module Hook
    include Constants

    def self.activate(args)
      repo = args[:configs]
      hook_args = ''
      hook_args <<= " -n #{args[:namespace]}" if args[:namespace]
      hook_args <<= " -b #{args[:branch]}" if args[:branch]
      hook = <<EOF
#!/usr/bin/env bash

current_branch=\`git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,'\`
git_dir=\`git rev-parse --show-toplevel\`
message=\`git log -1 --format=%B\`
msync -m "\$message"#{hook_args}
EOF
      File.open("#{repo}/#{HOOK_FILE}", 'w') do |file|
        file.write(hook)
      end
    end

    def self.deactivate(repo)
      hook_path = "#{repo}/#{HOOK_FILE}"
      File.delete(hook_path) if File.exist?(hook_path)
    end

    def self.hook(command, args)
      if (command == 'activate')
        activate(args)
      else
        deactivate(args[:configs])
      end
    end
  end
end
