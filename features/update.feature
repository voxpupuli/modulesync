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
    And the output should match:
      """
      There were no files to update
      """

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
