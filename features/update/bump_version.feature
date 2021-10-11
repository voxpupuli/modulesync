Feature: Bump a new version after an update
  Scenario: Bump the module version, update changelog and tag it after an update that produces changes
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And the puppet module "puppet-test" from "fakenamespace" has a file named "CHANGELOG.md" with:
      """
      ## 1965-04-14 - Release 0.4.2
      """
    And a file named "config_defaults.yml" with:
      """
      ---
      new-file:
        content: aruba
      """
    And a directory named "moduleroot"
    And a file named "moduleroot/new-file.erb" with:
      """
      <%= @configs['content'] %>
      """
    When I run `msync update --verbose --message "Add new-file" --bump --changelog --tag`
    Then the exit status should be 0
    And the file named "modules/fakenamespace/puppet-test/new-file" should contain "aruba"
    And the stdout should contain:
      """
      Bumped to version 0.4.3
      """
    And the stdout should contain:
      """
      Tagging with 0.4.3
      """
    And the file named "modules/fakenamespace/puppet-test/CHANGELOG.md" should contain "0.4.3"
    And the puppet module "puppet-test" from "fakenamespace" should have 2 commits made by "Aruba"
    And the puppet module "puppet-test" from "fakenamespace" should have a tag named "0.4.3"

  Scenario: Bump the module version after an update that produces changes
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And a file named "config_defaults.yml" with:
      """
      ---
      new-file:
        content: aruba
      """
    And a directory named "moduleroot"
    And a file named "moduleroot/new-file.erb" with:
      """
      <%= @configs['content'] %>
      """
    When I run `msync update --message "Add new-file" --bump`
    Then the exit status should be 0
    And the file named "modules/fakenamespace/puppet-test/new-file" should contain "aruba"
    And the stdout should contain:
      """
      Bumped to version 0.4.3
      """
    And the puppet module "puppet-test" from "fakenamespace" should have 2 commits made by "Aruba"
    And the puppet module "puppet-test" from "fakenamespace" should not have a tag named "0.4.3"

  Scenario: Bump the module version with changelog update when no CHANGELOG.md is available
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And a file named "config_defaults.yml" with:
      """
      ---
      new-file:
        content: aruba
      """
    And a directory named "moduleroot"
    And a file named "moduleroot/new-file.erb" with:
      """
      <%= @configs['content'] %>
      """
    When I run `msync update --message "Add new-file" --bump --changelog`
    Then the exit status should be 0
    And the file named "modules/fakenamespace/puppet-test/new-file" should contain "aruba"
    And the stdout should contain:
      """
      Bumped to version 0.4.3
      No CHANGELOG.md file found, not updating.
      """
    And the file named "modules/fakenamespace/puppet-test/CHANGELOG.md" should not exist
    And the puppet module "puppet-test" from "fakenamespace" should have 2 commits made by "Aruba"

  Scenario: Dont bump the module version after an update that produces no changes
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And a directory named "moduleroot"
    When I run `msync update --message "Add new-file" --bump --tag`
    Then the exit status should be 0
    And the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"
    And the puppet module "puppet-test" from "fakenamespace" should not have a tag named "0.4.3"
