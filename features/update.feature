Feature: update
  ModuleSync needs to update module boilerplate

  Scenario: Adding a new file
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And a file named "config_defaults.yml" with:
      """
      ---
      test:
        name: aruba
      """
    And a directory named "moduleroot"
    And a file named "moduleroot/test.erb" with:
      """
      <%= @configs['name'] %>
      """
    When I successfully run `msync update --noop`
    Then the output should match:
      """
      Files added:
      test
      """
    And the file named "modules/fakenamespace/puppet-test/test" should contain "aruba"

  Scenario: Using skip_broken option and adding a new file to repo without write access
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And the puppet module "puppet-test" from "fakenamespace" is read-only
    And a file named "config_defaults.yml" with:
      """
      ---
      test:
        name: aruba
      """
    And a directory named "moduleroot"
    And a file named "moduleroot/test.erb" with:
      """
      <%= @configs['name'] %>
      """
    When I successfully run `msync update -s -m "Add test"`
    Then the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"

  Scenario: Adding a new file to repo without write access
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And the puppet module "puppet-test" from "fakenamespace" is read-only
    And a file named "config_defaults.yml" with:
      """
      ---
      test:
        name: aruba
      """
    And a directory named "moduleroot"
    And a file named "moduleroot/test.erb" with:
      """
      <%= @configs['name'] %>
      """
    When I run `msync update -m "Add test" -r`
    Then the exit status should be 1
    And the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"

  Scenario: Adding a new file, without the .erb suffix
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
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
    When I successfully run `msync update --noop`
    Then the output should match:
      """
      Warning: using './moduleroot/test' as template without '.erb' suffix
      """
    And the output should match:
      """
      Files added:
      test
      """
    And the file named "modules/fakenamespace/puppet-test/test" should contain "aruba"
    And the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"

  Scenario: Adding a new file using global values
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And a file named "config_defaults.yml" with:
      """
      ---
      :global:
        name: aruba
      """
    And a directory named "moduleroot"
    And a file named "moduleroot/test.erb" with:
      """
      <%= @configs['name'] %>
      """
    When I successfully run `msync update --noop`
    Then the output should match:
      """
      Files added:
      test
      """
    And the file named "modules/fakenamespace/puppet-test/test" should contain "aruba"
    And the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"

  Scenario: Adding a new file overriding global values
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And a file named "config_defaults.yml" with:
      """
      ---
      :global:
        name: global

      test:
        name: aruba
      """
    And a directory named "moduleroot"
    And a file named "moduleroot/test.erb" with:
      """
      <%= @configs['name'] %>
      """
    When I successfully run `msync update --noop`
    Then the output should match:
      """
      Files added:
      test
      """
    And the file named "modules/fakenamespace/puppet-test/test" should contain "aruba"
    And the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"

  Scenario: Adding a new file ignoring global values
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And a file named "config_defaults.yml" with:
      """
      ---
      :global:
        key: global

      test:
        name: aruba
      """
    And a directory named "moduleroot"
    And a file named "moduleroot/test.erb" with:
      """
      <%= @configs['name'] %>
      """
    When I successfully run `msync update --noop`
    Then the output should match:
      """
      Files added:
      test
      """
    And the file named "modules/fakenamespace/puppet-test/test" should contain "aruba"
    And the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"

  Scenario: Adding a file that ERB can't parse
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And a file named "config_defaults.yml" with:
      """
      ---
      test:
        name: aruba
      """
    And a directory named "moduleroot"
    And a file named "moduleroot/test.erb" with:
      """
      <% @configs.each do |c| -%>
        <%= c['name'] %>
      <% end %>
      """
    When I run `msync update --noop`
    Then the exit status should be 1
    And the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"

  Scenario: Using skip_broken option with invalid files
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And a file named "config_defaults.yml" with:
      """
      ---
      test:
        name: aruba
      """
    And a directory named "moduleroot"
    And a file named "moduleroot/test.erb" with:
      """
      <% @configs.each do |c| -%>
        <%= c['name'] %>
      <% end %>
      """
    When I successfully run `msync update --noop -s`
    Then the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"

  Scenario: Using skip_broken and fail_on_warnings options with invalid files
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And a file named "config_defaults.yml" with:
      """
      ---
      test:
        name: aruba
      """
    And a directory named "moduleroot"
    And a file named "moduleroot/test.erb" with:
      """
      <% @configs.each do |c| -%>
        <%= c['name'] %>
      <% end %>
      """
    When I run `msync update --noop --skip_broken --fail_on_warnings`
    Then the exit status should be 1
    And the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"

  Scenario: Modifying an existing file
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And the puppet module "puppet-test" from "fakenamespace" has a file named "Gemfile" with:
      """
      source 'https://example.com'
      """
    And a file named "config_defaults.yml" with:
      """
      ---
      Gemfile:
        gem_source: https://somehost.com
      """
    And a directory named "moduleroot"
    And a file named "moduleroot/Gemfile.erb" with:
      """
      source '<%= @configs['gem_source'] %>'
      """
    When I successfully run `msync update --noop`
    Then the output should match:
      """
      Files changed:
      +diff --git a/Gemfile b/Gemfile
      """
    And the file named "modules/fakenamespace/puppet-test/Gemfile" should contain:
      """
      source 'https://somehost.com'
      """
    And the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"

  Scenario: Modifying an existing file and committing the change
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And the puppet module "puppet-test" from "fakenamespace" has a file named "Gemfile" with:
      """
      source 'https://example.com'
      """
    And a file named "config_defaults.yml" with:
      """
      ---
      Gemfile:
        gem_source: https://somehost.com
      """
    And a directory named "moduleroot"
    And a file named "moduleroot/Gemfile.erb" with:
      """
      source '<%= @configs['gem_source'] %>'
      """
    When I successfully run `msync update -m "Update Gemfile" -r test`
    Then the puppet module "puppet-test" from "fakenamespace" should have only 1 commit made by "Aruba"
    And the puppet module "puppet-test" from "fakenamespace" should have 1 commit made by "Aruba" in branch "test"
    And the puppet module "puppet-test" from "fakenamespace" should have a branch "test" with a file named "Gemfile" which contains:
      """
      source 'https://somehost.com'
      """

  Scenario: Setting an existing file to unmanaged
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And the puppet module "puppet-test" from "fakenamespace" has a file named "Gemfile" with:
      """
      source 'https://rubygems.org'
      """
    And a file named "config_defaults.yml" with:
      """
      ---
      Gemfile:
        unmanaged: true
        gem_source: https://somehost.com
      """
    And a directory named "moduleroot"
    And a file named "moduleroot/Gemfile.erb" with:
      """
      source '<%= @configs['gem_source'] %>'
      """
    When I successfully run `msync update --noop`
    Then the output should not match:
      """
      Files changed:
      +diff --git a/Gemfile b/Gemfile
      """
    And the output should match:
      """
      Not managing 'Gemfile' in 'puppet-test'
      """
    And the file named "modules/fakenamespace/puppet-test/Gemfile" should contain:
      """
      source 'https://rubygems.org'
      """
    And the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"

  Scenario: Setting an existing file to deleted
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And a file named "config_defaults.yml" with:
      """
      ---
      Gemfile:
        delete: true
      """
    And a directory named "moduleroot"
    And a file named "moduleroot/Gemfile.erb" with:
      """
      source '<%= @configs['gem_source'] %>'
      """
    And the puppet module "puppet-test" from "fakenamespace" has a file named "Gemfile" with:
      """
      source 'https://rubygems.org'
      """
    When I successfully run `msync update --noop`
    Then the output should match:
      """
      Files changed:
      diff --git a/Gemfile b/Gemfile
      deleted file mode 100644
      """
    And the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"

  Scenario: Setting a non-existent file to deleted
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And a file named "config_defaults.yml" with:
      """
      ---
      doesntexist_file:
        delete: true
      """
    And a directory named "moduleroot"
    When I successfully run `msync update -m 'deletes a file that doesnt exist!' -f puppet-test`
    Then the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"

  Scenario: Setting a directory to unmanaged
    Given a basic setup with a puppet module "puppet-apache" from "puppetlabs"
    And I successfully run `msync clone`
    And a file named "config_defaults.yml" with:
      """
      ---
      spec:
        unmanaged: true
      """
    And a directory named "moduleroot/spec"
    And a file named "moduleroot/spec/spec_helper.rb.erb" with:
      """
      some spec_helper fud
      """
    And a directory named "modules/puppetlabs/puppet-apache/spec"
    And a file named "modules/puppetlabs/puppet-apache/spec/spec_helper.rb" with:
      """
      This is a fake spec_helper!
      """
    When I successfully run `msync update --offline`
    Then the output should contain:
      """
      Not managing 'spec/spec_helper.rb' in 'puppet-apache'
      """
    And the file named "modules/puppetlabs/puppet-apache/spec/spec_helper.rb" should contain:
      """
      This is a fake spec_helper!
      """
    And the puppet module "puppet-apache" from "puppetlabs" should have no commits made by "Aruba"

  Scenario: Adding a new file in a new subdirectory
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And a file named "config_defaults.yml" with:
      """
      ---
      spec/spec_helper.rb:
        require:
          - puppetlabs_spec_helper/module_helper
      """
    And a file named "moduleroot/spec/spec_helper.rb.erb" with:
      """
      <% @configs['require'].each do |required| -%>
        require '<%= required %>'
      <% end %>
      """
    When I successfully run `msync update --noop`
    Then the output should match:
      """
      Files added:
      spec/spec_helper.rb
      """
    And the file named "modules/fakenamespace/puppet-test/spec/spec_helper.rb" should contain:
      """
      require 'puppetlabs_spec_helper/module_helper'
      """
    And the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"

  Scenario: Updating offline
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And I successfully run `msync clone`
    And a file named "config_defaults.yml" with:
      """
      ---
      spec/spec_helper.rb:
        require:
          - puppetlabs_spec_helper/module_helper
      """
    And a file named "moduleroot/spec/spec_helper.rb.erb" with:
      """
      <% @configs['require'].each do |required| -%>
        require '<%= required %>'
      <% end %>
      """
    When I successfully run `msync update --offline`
    Then the output should not match /Files (changed|added|deleted):/
    And the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"

  Scenario: Pulling a module that already exists in the modules directory
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And a directory named "moduleroot"
    When I successfully run `msync update --message "First update run"`
    Then the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"
    Given a file named "config_defaults.yml" with:
      """
      ---
      spec/spec_helper.rb:
        require:
          - puppetlabs_spec_helper/module_helper
      """
    And a file named "moduleroot/spec/spec_helper.rb.erb" with:
      """
      <% @configs['require'].each do |required| -%>
        require '<%= required %>'
      <% end %>
      """
    When I successfully run `msync update --noop`
    Then the output should match:
      """
      Files added:
      spec/spec_helper.rb
      """
    And the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"

  Scenario: When running update without changes
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And a directory named "moduleroot"
    When I successfully run `msync update --verbose --message "Running without changes"`
    Then the stdout should contain "There were no changes in 'modules/fakenamespace/puppet-test'. Not committing."
    And the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"

  Scenario: When specifying configurations in managed_modules.yml
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And a file named "managed_modules.yml" with:
      """
      ---
        puppet-test:
          module_name: test
      """
    And a file named "config_defaults.yml" with:
      """
      ---
      test:
        name: aruba
      """
    And a directory named "moduleroot"
    And a file named "moduleroot/test.erb" with:
      """
      <%= @configs['name'] %>
      """
    When I successfully run `msync update --noop`
    Then the output should match:
      """
      Files added:
      test
      """
    And the file named "modules/fakenamespace/puppet-test/test" should contain "aruba"
    And the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"

  Scenario: When specifying configurations in managed_modules.yml and using a filter
    Given a mocked git configuration
    And a puppet module "puppet-test" from "fakenamespace"
    And a puppet module "puppet-blacksmith" from "fakenamespace"
    And a file named "managed_modules.yml" with:
      """
      ---
        puppet-blacksmith:
        puppet-test:
          module_name: test
      """
    And a file named "modulesync.yml" with:
      """
      ---
      namespace: fakenamespace
      """
    And a git_base option appended to "modulesync.yml" for local tests
    And a file named "config_defaults.yml" with:
      """
      ---
      test:
        name: aruba
      """
    And a directory named "moduleroot"
    And a file named "moduleroot/test.erb" with:
      """
      <%= @configs['name'] %>
      """
    When I successfully run `msync update --noop -f puppet-test`
    Then the output should match:
      """
      Files added:
      test
      """
    And the file named "modules/fakenamespace/puppet-test/test" should contain "aruba"
    And a directory named "modules/fakenamespace/puppet-blacksmith" should not exist
    And the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"

  Scenario: When specifying configurations in managed_modules.yml and using a negative filter
    Given a mocked git configuration
    And a puppet module "puppet-test" from "fakenamespace"
    And a puppet module "puppet-blacksmith" from "fakenamespace"
    And a file named "managed_modules.yml" with:
      """
      ---
        puppet-blacksmith:
        puppet-test:
          module_name: test
      """
    And a file named "modulesync.yml" with:
      """
      ---
      namespace: fakenamespace
      """
    And a git_base option appended to "modulesync.yml" for local tests
    And a file named "config_defaults.yml" with:
      """
      ---
      test:
        name: aruba
      """
    And a directory named "moduleroot"
    And a file named "moduleroot/test.erb" with:
      """
      <%= @configs['name'] %>
      """
    When I successfully run `msync update --noop -x puppet-blacksmith`
    Then the output should match:
      """
      Files added:
      test
      """
    And the file named "modules/fakenamespace/puppet-test/test" should contain "aruba"
    And a directory named "modules/fakenamespace/puppet-blacksmith" should not exist
    And the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"

  Scenario: Updating a module with a .sync.yml file
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And a file named "config_defaults.yml" with:
      """
      ---
      :global:
        global-default: some-default
        global-to-overwrite: to-be-overwritten
      spec/spec_helper.rb:
        require:
          - puppetlabs_spec_helper/module_helper
      """
    And a file named "moduleroot/spec/spec_helper.rb.erb" with:
      """
      <% @configs['require'].each do |required| -%>
        require '<%= required %>'
      <% end %>
      """
    And a file named "moduleroot/global-test.md.erb" with:
      """
      <%= @configs['global-default'] %>
      <%= @configs['global-to-overwrite'] %>
      <%= @configs['module-default'] %>
      """
    And the puppet module "puppet-test" from "fakenamespace" has a file named ".sync.yml" with:
      """
      ---
      :global:
        global-to-overwrite: it-is-overwritten
        module-default: some-value
      spec/spec_helper.rb:
        unmanaged: true
      """
    When I successfully run `msync update --noop`
    Then the output should match:
      """
      Not managing 'spec/spec_helper.rb' in 'puppet-test'
      """
    And the file named "modules/fakenamespace/puppet-test/global-test.md" should contain:
      """
      some-default
      it-is-overwritten
      some-value
      """
    And the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"

  Scenario: Module with custom namespace
    Given a mocked git configuration
    And a puppet module "puppet-test" from "fakenamespace"
    And a puppet module "puppet-lib-file_concat" from "electrical"
    And a file named "managed_modules.yml" with:
      """
      ---
        - puppet-test
        - electrical/puppet-lib-file_concat
      """
    And a file named "modulesync.yml" with:
      """
      ---
      namespace: fakenamespace
      """
    And a git_base option appended to "modulesync.yml" for local tests
    And a file named "config_defaults.yml" with:
      """
      ---
      test:
        name: aruba
      """
    And a directory named "moduleroot"
    And a file named "moduleroot/test.erb" with:
      """
      <%= @configs['name'] %>
      """
    When I successfully run `msync update --noop`
    Then the output should match:
      """
      Files added:
      test
      """
    And the file named "modules/fakenamespace/puppet-test/.git/config" should match /^\s+url = .*fakenamespace.puppet-test$/
    And the file named "modules/electrical/puppet-lib-file_concat/.git/config" should match /^\s+url = .*electrical.puppet-lib-file_concat$/
    And the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"
    And the puppet module "puppet-lib-file_concat" from "electrical" should have no commits made by "Aruba"

  Scenario: Modifying an existing file with values exposed by the module
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And a file named "config_defaults.yml" with:
      """
      ---
      README.md:
      """
    And a directory named "moduleroot"
    And a file named "moduleroot/README.md.erb" with:
      """
      module: <%= @configs[:puppet_module] %>
      namespace: <%= @configs[:namespace] %>
      """
    And the puppet module "puppet-test" from "fakenamespace" has a file named "README.md" with:
      """
      Hello world!
      """
    When I successfully run `msync update --noop`
    Then the output should match:
      """
      Files changed:
      +diff --git a/README.md b/README.md
      """
    And the file named "modules/fakenamespace/puppet-test/README.md" should contain:
      """
      module: puppet-test
      namespace: fakenamespace
      """
    And the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"

  Scenario: Running the same update twice and pushing to a remote branch
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And a file named "config_defaults.yml" with:
      """
      ---
      Gemfile:
        gem_source: https://somehost.com
      """
    And a directory named "moduleroot"
    And a file named "moduleroot/Gemfile.erb" with:
      """
      source '<%= @configs['gem_source'] %>'
      """
    When I successfully run `msync update -m "Update Gemfile" -r test`
    Then the puppet module "puppet-test" from "fakenamespace" should have only 1 commit made by "Aruba"
    And the puppet module "puppet-test" from "fakenamespace" should have 1 commit made by "Aruba" in branch "test"
    Given I remove the directory "modules"
    When I successfully run `msync update -m "Update Gemfile" -r test`
    Then the output should not contain "error"
    Then the output should not contain "rejected"
    And the puppet module "puppet-test" from "fakenamespace" should have only 1 commit made by "Aruba"
    And the puppet module "puppet-test" from "fakenamespace" should have 1 commit made by "Aruba" in branch "test"

  Scenario: Repository with a default branch other than master
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And the puppet module "puppet-test" from "fakenamespace" has the default branch named "develop"
    And a file named "config_defaults.yml" with:
      """
      ---
      Gemfile:
        gem_source: https://somehost.com
      """
    And a directory named "moduleroot"
    And a file named "moduleroot/Gemfile.erb" with:
      """
      source '<%= @configs['gem_source'] %>'
      """
    When I successfully run `msync update --verbose -m "Update Gemfile"`
    Then the output should contain "Using repository's default branch: develop"
    And the puppet module "puppet-test" from "fakenamespace" should have only 1 commit made by "Aruba"
    And the puppet module "puppet-test" from "fakenamespace" should have 1 commit made by "Aruba" in branch "develop"

  Scenario: Adding a new file from a template using metadata
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And a file named "config_defaults.yml" with:
      """
      ---
      """
    And a directory named "moduleroot"
    And a file named "moduleroot/test.erb" with:
      """
      module: <%= @metadata[:module_name] %>
      namespace: <%= @metadata[:namespace] %>
      target: <%= @metadata[:target_file] %>
      workdir: <%= @metadata[:workdir] %>
      """
    When I successfully run `msync update --noop`
    Then the file named "modules/fakenamespace/puppet-test/test" should contain:
      """
      module: puppet-test
      namespace: fakenamespace
      target: modules/fakenamespace/puppet-test/test
      workdir: modules/fakenamespace/puppet-test
      """
    And the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"

  # This reproduces the issue: https://github.com/voxpupuli/modulesync/issues/81
  Scenario: Resync repositories after upstream branch deletion
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And a file named "config_defaults.yml" with:
      """
      ---
      test:
        name: aruba
      """
    And a directory named "moduleroot"
    And a file named "moduleroot/test.erb" with:
      """
      <%= @configs['name'] %>
      """
    When I successfully run `msync update -m "No changes!" --branch delete-me`
    Then the puppet module "puppet-test" from "fakenamespace" should have 1 commit made by "Aruba" in branch "delete-me"
    When the branch "delete-me" of the puppet module "puppet-test" from "fakenamespace" is deleted
    And I successfully run `msync update -m "No changes!" --branch delete-me`
    Then the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"
