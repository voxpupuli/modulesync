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
    Then the output should match:
      """
      Files added:\s+
      test
      """
    And the exit status should be 0
    Given I run `cat modules/puppet-test/test`
    Then the output should contain "aruba"

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
    Then the output should match:
      """
      Files changed:\s+
      +diff --git a/Gemfile b/Gemfile
      """
    And the exit status should be 0
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
    Then the output should match:
      """
      Files added:\s+
      spec/spec_helper.rb
      """
    And the exit status should be 0
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
    Then the output should not match /Files (changed|added|deleted):/
    And the exit status should be 0

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
    #Then the exit status should be 0
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
    Then the output should not match /Files changed\s+/
    And the output should not match /Files added\s+/
    And the output should not match /Files deleted\s+/
    And the exit status should be 0

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
    Then the output should match:
      """
      Files added:\s+
      test
      """
    And the exit status should be 0
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
    Then the output should match:
      """
      Files added:\s+
      test
      """
    And the exit status should be 0
    Given I run `cat modules/puppet-test/test`
    Then the output should contain "aruba"
    And a directory named "modules/puppet-blacksmith" should not exist

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
    And a file named "moduleroot/.travis.yml" with:
      """
      ---
      sudo: false
      language: ruby
      cache: bundler
      bundler_args: --without system_tests
      script: "bundle exec rake validate && bundle exec rake lint && bundle exec rake spec SPEC_OPTS='--color --format documentation'"
      matrix:
        fast_finish: true
        include:
        - rvm: 1.8.7
          env: PUPPET_GEM_VERSION="~> 3.0"
        - rvm: 1.9.3
          env: PUPPET_GEM_VERSION="~> 3.0"
        - rvm: 2.1.5
          env: PUPPET_GEM_VERSION="~> 3.0"
        - rvm: 2.1.5
          env: PUPPET_GEM_VERSION="~> 3.0" FUTURE_PARSER="yes"
        - rvm: 2.1.6
          env: PUPPET_GEM_VERSION="~> 4.0" STRICT_VARIABLES="yes"
      notifications:
        email: false
      """
    When I run `msync update --noop`
    Then the output should match:
      """
      Not managing spec/spec_helper.rb in puppetlabs-stdlib
      """
    And the exit status should be 0

  Scenario: Module with custom namespace
    Given a file named "managed_modules.yml" with:
      """
      ---
        - puppet-test
        - electrical/puppet-lib-file_concat
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
    Then the output should match:
      """
      Files added:\s+
      test
      """
    And the exit status should be 0
    Given I run `cat modules/puppet-test/.git/config`
    Then the output should contain "url = https://github.com/maestrodev/puppet-test.git"
    Given I run `cat modules/puppet-lib-file_concat/.git/config`
    Then the output should contain "url = https://github.com/electrical/puppet-lib-file_concat.git"

  Scenario: Providing a custom modules directory in the configuration file
    Given a file named "managed_modules.yml" with:
      """
      ---
        - puppet-test
      """
    And a file named "modulesync.yml" with:
      """
      ---
        modules_dir: foo
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
    Then the output should match:
      """
      Files added:\s+
      test
      """
    And the exit status should be 0
    Given I run `cat foo/puppet-test/.git/config`
    Then the output should contain "url = https://github.com/maestrodev/puppet-test.git"

  Scenario: Providing a custom modules directory at the command line
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
    When I run `msync update --noop --modules-dir foo`
    Then the output should match:
      """
      Files added:\s+
      test
      """
    And the exit status should be 0
    Given I run `cat foo/puppet-test/.git/config`
    Then the output should contain "url = https://github.com/maestrodev/puppet-test.git"
