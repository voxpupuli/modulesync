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
    And the output should match /Files added:\s+test/
    Given I run `cat modules/puppet-test/test`
    Then the output should contain "aruba"

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
      Files changed:\s+
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
      Files added:\s+
      spec/spec_helper.rb
      """
    Given I run `cat modules/puppet-test/spec/spec_helper.rb`
    Then the output should contain:
      """
      require 'puppetlabs_spec_helper/module_helper'
      """
    When I run `msync update --offline --noop`
    Then the exit status should be 0
    And the output should match:
      """
      Files added:\s+
      spec/spec_helper.rb
      """
    When I run `msync update --offline`
    Then the exit status should be 0
    And the output should match:
      """
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
    Then the exit status should be 0
    And the output should match:
      """
      Not managing spec/spec_helper.rb in puppetlabs-stdlib
      """
