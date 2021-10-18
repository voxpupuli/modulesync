require 'modulesync'

module ModuleSync
  class Hook
    attr_reader :hook_file, :namespace, :branch, :args

    def initialize(hook_file, options = [])
      @hook_file = hook_file
      @namespace = options['namespace']
      @branch = options['branch']
      @args = options['hook_args']
    end

    def content(arguments)
      <<~CONTENT
        #!/usr/bin/env bash

        current_branch=\`git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,'\`
        git_dir=\`git rev-parse --show-toplevel\`
        message=\`git log -1 --format=%B\`
        msync -m "\$message" #{arguments}
      CONTENT
    end

    def activate
      hook_args = []
      hook_args << "-n #{namespace}" if namespace
      hook_args << "-b #{branch}" if branch
      hook_args << args if args

      File.open(hook_file, 'w') do |file|
        file.write(content(hook_args.join(' ')))
      end
    end

    def deactivate
      File.delete(hook_file) if File.exist?(hook_file)
    end
  end
end
