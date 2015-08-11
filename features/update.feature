@announce
Feature: update
  ModuleSync needs to update module boilerplate

  Scenario: Adding a new file
    Given a file named "managed_modules.yml" with:
      """
      ---
        - puppet-test
      """
    And a file named "modulesync.yml" with:
      """
      ---
        namespace: maestrodev
        git_base: https://github.com/
      """
    And a file named "config_defaults.yml" with:
      """
      ---
      test:
        name: aruba
      """
    And a directory named "moduleroot"
    And a file named "moduleroot/test" with:
      """
      <%= @configs['name'] %>
      """
    When I run `msync update --noop`
    Then the exit status should be 0
    And the output should match:
      """
      Files added:
      ============
      test
      """
    Given I run `cat modules/puppet-test/test`
    Then the output should contain "aruba"

  Scenario: Deleting an existing file
    Given a file named "managed_modules.yml" with:
      """
      ---
        - puppet-test
      """
    And a file named "modulesync.yml" with:
      """
      ---
        namespace: maestrodev
        git_base: https://github.com/
      """
    And a file named "config_defaults.yml" with:
      """
      ---
        README.md:
          delete: true
      """
    And a directory named "moduleroot"
    When I run `msync update --noop`
    Then the exit status should be 0
    And the file "modules/puppet-test/README.md" should not exist
    And the output should match:
      """
      Files deleted:
      ==============
      README.md
      """

  Scenario: Adding a file that ERB can't parse
    Given a file named "managed_modules.yml" with:
      """
      ---
        - puppet-test
      """
    And a file named "modulesync.yml" with:
      """
      ---
        namespace: maestrodev
        git_base: https://github.com/
      """
    And a file named "config_defaults.yml" with:
      """
      ---
      test:
        name: aruba
      """
    And a directory named "moduleroot"
    And a file named "moduleroot/test" with:
      """
      <% @configs.each do |c| -%>
        <%= c['name'] %>
      <% end %>
      """
    When I run `msync update --noop`
    Then the exit status should be 1
    And the output should match /Could not parse ERB template/

  Scenario: Modifying an existing file
    Given a file named "managed_modules.yml" with:
      """
      ---
        - puppet-test
      """
    And a file named "modulesync.yml" with:
      """
      ---
        namespace: maestrodev
        git_base: https://github.com/
      """
    And a file named "config_defaults.yml" with:
      """
      ---
      Gemfile:
        gem_source: https://somehost.com
      """
    And a directory named "moduleroot"
    And a file named "moduleroot/Gemfile" with:
      """
      source '<%= @configs['gem_source'] %>'
      """
    When I run `msync update --noop`
    Then the exit status should be 0
    And the output should match:
      """
      Files changed:
      ==============
      +diff --git a/Gemfile b/Gemfile
      """
    Given I run `cat modules/puppet-test/Gemfile`
    Then the output should contain:
      """
      source 'https://somehost.com'
      """

  Scenario: Adding a new file in a new subdirectory
    Given a file named "managed_modules.yml" with:
      """
      ---
        - puppet-test
      """
    And a file named "modulesync.yml" with:
      """
      ---
        namespace: maestrodev
        git_base: https://github.com/
      """
    And a file named "config_defaults.yml" with:
      """
      ---
      spec/spec_helper.rb:
        require:
          - puppetlabs_spec_helper/module_helper
      """
    And a file named "moduleroot/spec/spec_helper.rb" with:
      """
      <% @configs['require'].each do |required| -%>
        require '<%= required %>'
      <% end %>
      """
    When I run `msync update --noop`
    Then the exit status should be 0
    And the output should match:
      """
      Files added:
      ============
      spec/spec_helper.rb
      """
    Given I run `cat modules/puppet-test/spec/spec_helper.rb`
    Then the output should contain:
      """
      require 'puppetlabs_spec_helper/module_helper'
      """

  Scenario: Updating offline
    Given a file named "managed_modules.yml" with:
      """
      ---
        - puppet-test
      """
    And a file named "modulesync.yml" with:
      """
      ---
        namespace: maestrodev
        git_base: https://github.com/
      """
    And a file named "config_defaults.yml" with:
      """
      ---
      spec/spec_helper.rb:
        require:
          - puppetlabs_spec_helper/module_helper
      """
    And a file named "moduleroot/spec/spec_helper.rb" with:
      """
      <% @configs['require'].each do |required| -%>
        require '<%= required %>'
      <% end %>
      """
    When I run `msync update --offline`
    Then the exit status should be 0
    And the output should not match /Files (changed|added|deleted):/

  Scenario: Pulling a module that already exists in the modules directory
    Given a file named "managed_modules.yml" with:
      """
      ---
        - puppetlabs-stdlib
      """
    And a file named "modulesync.yml" with:
      """
      ---
        git_base: https://github.com/
      """
    And a file named "config_defaults.yml" with:
      """
      ---
      spec/spec_helper.rb:
        require:
          - puppetlabs_spec_helper/module_helper
      """
    And a file named "moduleroot/spec/spec_helper.rb" with:
      """
      <% @configs['require'].each do |required| -%>
        require '<%= required %>'
      <% end %>
      """
    Given I run `git init modules/puppetlabs-stdlib`
    Given a file named "modules/puppetlabs-stdlib/.git/config" with:
      """
      [core]
          repositoryformatversion = 0
          filemode = true
          bare = false
          logallrefupdates = true
          ignorecase = true
          precomposeunicode = true
      [remote "origin"]
          url = https://github.com/puppetlabs/puppetlabs-stdlib.git
          fetch = +refs/heads/*:refs/remotes/origin/*
      """
    When I run `msync update --noop`
    Then the exit status should be 0
    And the output should match:
      """
      Not managing spec/spec_helper.rb in puppetlabs-stdlib
      """

  Scenario: When running update with no changes
    Given a file named "managed_modules.yml" with:
      """
      ---
        - puppet-test
      """
    And a file named "modulesync.yml" with:
      """
      ---
        namespace: maestrodev
        git_base: https://github.com/
      """
    And a directory named "moduleroot"
    When I run `msync update --noop`
    Then the exit status should be 0
    And the output should not match /Files changed/
    And the output should not match /Files added/
    And the output should not match /Files deleted/

  Scenario: Updating a module with a .sync.yml file
    Given a file named "managed_modules.yml" with:
      """
      ---
        - puppetlabs-stdlib
      """
    And a file named "modulesync.yml" with:
      """
      ---
        git_base: https://github.com/
      """
    And a file named "config_defaults.yml" with:
      """
      ---
      spec/spec_helper.rb:
        require:
          - puppetlabs_spec_helper/module_helper
      """
    And a file named "moduleroot/spec/spec_helper.rb" with:
      """
      <% @configs['require'].each do |required| -%>
        require '<%= required %>'
      <% end %>
      """
    When I run `msync update --noop`
    Then the exit status should be 0
    And the output should match:
      """
      Not managing spec/spec_helper.rb in puppetlabs-stdlib
      """

  Scenario: Using a pre-commit-script
    Given a file named "managed_modules.yml" with:
      """
      ---
        - puppet-test
      """
    And a file named "modulesync.yml" with:
      """
      ---
        namespace: maestrodev
        git_base: https://github.com/
        hooks:
          pre_commit: hooks/pre_commit_script.sh
          pre_push: hooks/pre_push_script.sh
      """
    And a file named "config_defaults.yml" with:
      """
      ---
      test:
        name: aruba
      """
    And a directory named "moduleroot"
    And a file named "moduleroot/test" with:
      """
      <%= @configs['name'] %>
      """
    And a file named "hooks/pre_commit_script.sh" with:
      """
      #!/usr/bin/env bash
      touch $1/.git/hooks/pre-commit
      """
    And a file named "hooks/pre_push_script.sh" with:
      """
      #!/usr/bin/env bash
      touch $1/.git/hooks/pre-push
      """
    When I run `chmod +x hooks/pre_commit_script.sh hooks/pre_push_script.sh`
    When I run `msync update --noop`
    Then the exit status should be 0
    And the output should match /Running pre_commit script/
    And the output should match /Running pre_push script/
    And the following files should exist:
      | modules/puppet-test/.git/hooks/pre-commit |
      | modules/puppet-test/.git/hooks/pre-push   |
    And the output should match:
      """
      Files added:
      ============
      test
      """
    Given I run `cat modules/puppet-test/test`
    Then the output should contain "aruba"

  Scenario: When specifying configurations in managed_modules.yml
    Given a file named "managed_modules.yml" with:
      """
      ---
        puppet-test:
          module_name: test
      """
    And a file named "modulesync.yml" with:
      """
      ---
        namespace: maestrodev
        git_base: https://github.com/
      """
    And a file named "config_defaults.yml" with:
      """
      ---
      test:
        name: aruba
      """
    And a directory named "moduleroot"
    And a file named "moduleroot/test" with:
      """
      <%= @configs['name'] %>
      """
    When I run `msync update --noop`
    Then the exit status should be 0
    And the output should match:
      """
      Files added:
      ============
      test
      """
    Given I run `cat modules/puppet-test/test`
    Then the output should contain "aruba"

  Scenario: When specifying configurations in managed_modules.yml and using a filter
    Given a file named "managed_modules.yml" with:
      """
      ---
        puppet-blacksmith:
        puppet-test:
          module_name: test
      """
    And a file named "modulesync.yml" with:
      """
      ---
        namespace: maestrodev
        git_base: https://github.com/
      """
    And a file named "config_defaults.yml" with:
      """
      ---
      test:
        name: aruba
      """
    And a directory named "moduleroot"
    And a file named "moduleroot/test" with:
      """
      <%= @configs['name'] %>
      """
    When I run `msync update --noop -f puppet-test`
    Then the exit status should be 0
    And the output should match:
      """
      Files added:
      ============
      test
      """
    Given I run `cat modules/puppet-test/test`
    Then the output should contain "aruba"
    And a directory named "modules/puppet-blacksmith" should not exist

  Scenario: When specifying the remote url in managed_modules.yml
    Given a file named "managed_modules.yml" with:
      """
      ---
        puppetlabs-stdlib:
          remote: https://github.com/puppetlabs/puppetlabs-stdlib
      """
    And a file named "modulesync.yml" with:
      """
      ---
        namespace: maestrodev
        git_base: https://github.com/
      """
    And a directory named "moduleroot"
    When I run `msync update --noop`
    Then the exit status should be 0
    And a directory named "modules/puppetlabs-stdlib" should exist
    And the file "modules/puppetlabs-stdlib/.git/config" should contain:
      """
      [remote "origin"]
      	url = https://github.com/puppetlabs/puppetlabs-stdlib
      """

  Scenario: When overriding the namespace in managed_modules.yml
    Given a file named "managed_modules.yml" with:
      """
      ---
        puppet-test:
        puppetlabs-stdlib:
          namespace: puppetlabs
      """
    And a file named "modulesync.yml" with:
      """
      ---
        namespace: maestrodev
        git_base: https://github.com/
      """
    And a directory named "moduleroot"
    When I run `msync update --noop`
    Then the exit status should be 0
    And the following directories should exist:
      | modules/puppetlabs-stdlib |
      | modules/puppet-test       |
    And the file "modules/puppetlabs-stdlib/.git/config" should contain:
      """
      [remote "origin"]
      	url = https://github.com/puppetlabs/puppetlabs-stdlib
      """
    And the file "modules/puppet-test/.git/config" should contain:
      """
      [remote "origin"]
      	url = https://github.com/maestrodev/puppet-test
      """

  Scenario: When specifying a nonexistent pre-commit hook
    Given a file named "managed_modules.yml" with:
    """
    ---
      - puppetlabs-stdlib
    """
    And a file named "modulesync.yml" with:
      """
      ---
        namespace: puppetlabs
        git_base: https://github.com/
        hooks:
          pre_commit: hooks/project_pre_commit_script.sh
      """
    And a directory named "moduleroot"
    When I run `msync update --noop`
    Then the exit status should be 1
    And the output should match /No pre_commit script found at/

  Scenario: When specifying a pre-commit hook that's not executable
    Given a file named "managed_modules.yml" with:
    """
    ---
      - puppetlabs-stdlib
    """
    And a file named "modulesync.yml" with:
      """
      ---
        namespace: puppetlabs
        git_base: https://github.com/
        hooks:
          pre_commit: hooks/project_pre_commit_script.sh
      """
    And an empty file named "hooks/project_pre_commit_script.sh"
    And a directory named "moduleroot"
    When I run `msync update --noop`
    Then the exit status should be 1
    And the output should match /The script \S+project_pre_commit_script.sh is not executable/

  Scenario: When specifying a pre-push hook in managed_modules.yml
    Given a file named "managed_modules.yml" with:
      """
      ---
        puppetlabs-stdlib:
          hooks:
            pre_push: hooks/pre_push_script.sh
            pre_commit: hooks/pre_commit_script.sh
      """
    And a file named "modulesync.yml" with:
      """
      ---
        namespace: puppetlabs
        git_base: https://github.com/
        hooks:
          pre_commit: hooks/project_pre_commit_script.sh
      """
    And a file named "config_defaults.yml" with:
      """
      ---
      test:
        name: aruba
      """
    And a directory named "moduleroot"
    And a file named "moduleroot/test" with:
      """
      <%= @configs['name'] %>
      """
    And a file named "hooks/project_pre_commit_script.sh" with:
      """
      #!/usr/bin/env bash
      touch $1/.git/hooks/project-pre-commit
      """
    And a file named "hooks/pre_commit_script.sh" with:
      """
      #!/usr/bin/env bash
      touch $1/.git/hooks/pre-commit
      """
    And a file named "hooks/pre_push_script.sh" with:
      """
      #!/usr/bin/env bash
      touch $1/.git/hooks/pre-push
      """
    When I run `chmod +x hooks/project_pre_commit_script.sh hooks/pre_commit_script.sh hooks/pre_push_script.sh`
    When I run `msync update --noop`
    Then the exit status should be 0
    And the output should match:
      """
      Files added:
      ============
      test
      """
    And the output should match /Running pre_commit script/
    And the output should match /Running pre_push script/
    And the following files should exist:
      | modules/puppetlabs-stdlib/.git/hooks/pre-commit |
      | modules/puppetlabs-stdlib/.git/hooks/pre-push   |
    And the file "modules/puppetlabs-stdlib/.git/hooks/project-pre-commit" should not exist

  Scenario: When specifying a new local branch at the command line
    Given a file named "managed_modules.yml" with:
      """
      ---
        - puppetlabs-stdlib
      """
    And a file named "modulesync.yml" with:
      """
      ---
        namespace: puppetlabs
        git_base: https://github.com/
      """
    And a directory named "moduleroot"
    When I run `msync update --noop -b somenewlocalbranch`
    Then the exit status should be 0
    And the file "modules/puppetlabs-stdlib/.git/HEAD" should contain:
      """
      ref: refs/heads/somenewlocalbranch
      """

  Scenario: When specifying a remote branch at the command line
    Given a file named "managed_modules.yml" with:
      """
      ---
        - puppetlabs-stdlib
      """
    And a file named "modulesync.yml" with:
      """
      ---
        namespace: puppetlabs
        git_base: https://github.com/
      """
    And a directory named "moduleroot"
    When I run `msync update --noop -r 2.1.x`
    Then the exit status should be 0
    And the file "modules/puppetlabs-stdlib/.git/HEAD" should contain:
      """
      ref: refs/heads/2.1.x
      """
