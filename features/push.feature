Feature: push
  Push commits to remote

  Scenario: Push available commits to remote
    Given a mocked git configuration
    And a puppet module "puppet-test" from "awesome"
    And a file named "managed_modules.yml" with:
    """
    ---
    puppet-test:
      namespace: awesome
    """
    And a file named "modulesync.yml" with:
    """
    ---
    branch: modulesync
    """
    And a git_base option appended to "modulesync.yml" for local tests
    And I successfully run `msync reset`
    And I cd to "modules/awesome/puppet-test"
    And I run `touch hello`
    And I run `git add hello`
    And I run `git commit -m'Hello!'`
    And I cd to "~"
    Then the puppet module "puppet-test" from "awesome" should have no commits made by "Aruba"
    When I successfully run `msync push --verbose`
    Then the puppet module "puppet-test" from "awesome" should have 1 commit made by "Aruba" in branch "modulesync"

  Scenario: Push command without a branch sets
    Given a basic setup with a puppet module "puppet-test" from "awesome"
    When I run `msync push --verbose`
    Then the exit status should be 1
    And the stderr should contain:
    """
    Error: 'branch' option is missing, please set it in configuration or in command line.
    """

  Scenario: Report the need to clone repositories if sourcecode was not cloned before
    Given a basic setup with a puppet module "puppet-test" from "awesome"
    And the global option "branch" sets to "modulesync"
    When I run `msync push --verbose`
    Then the exit status should be 1
    And the stderr should contain:
    """
    puppet-test: Repository must be locally available before trying to push
    """
