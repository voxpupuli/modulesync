require 'modulesync'

module ModuleSync
  class Hook
    attr_reader :hook_file, :namespace, :branch

    def initialize(hook_file, namespace = nil, branch = nil)
      @hook_file = hook_file
      @namespace = namespace
      @branch = branch
    end

    def content(args)
      return <<-EOF
#!/usr/bin/env bash

current_branch=\`git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,'\`
git_dir=\`git rev-parse --show-toplevel\`
message=\`git log -1 --format=%B\`
msync -m "\$message"#{args}
EOF
    end

    def activate
      hook_args = ''
      hook_args <<= " -n #{namespace}" if namespace
      hook_args <<= " -b #{branch}" if branch

      File.open(hook_file, 'w') do |file|
        file.write(content(hook_args))
      end
    end

    def deactivate
      File.delete(hook_file) if File.exist?(hook_file)
    end
  end
end
