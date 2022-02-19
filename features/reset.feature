Feature: reset
  Reset all repositories

  Scenario: Running first reset to clone repositories
    Given a basic setup with a puppet module "puppet-test" from "awesome"
    And the global option "branch" sets to "modulesync"
    When I successfully run `msync reset --verbose`
    Then the output should contain "Cloning from 'file://"
    And the output should not contain "Hard-resetting any local changes to repository in"

  @no-clobber
  Scenario: Reset when sourcecodes have already been cloned
    Given the file "modules/awesome/puppet-test/metadata.json" should exist
    And the global option "branch" sets to "modulesync"
    When I successfully run `msync reset --verbose`
    Then the output should not contain "Cloning from 'file://"
    And the output should contain "Hard-resetting any local changes to repository in 'modules/awesome/puppet-test' from branch 'origin/master'"

  Scenario: Reset after an upstream file addition
    Given a basic setup with a puppet module "puppet-test" from "awesome"
    And the global option "branch" sets to "modulesync"
    And I successfully run `msync reset`
    Then the file "modules/awesome/puppet-test/hello" should not exist
    When the puppet module "puppet-test" from "awesome" has a file named "hello" with:
    """
    Hello
    """
    When I successfully run `msync reset --verbose`
    Then the output should contain "Hard-resetting any local changes to repository in 'modules/awesome/puppet-test' from branch 'origin/master'"
    And the file "modules/awesome/puppet-test/hello" should exist

  Scenario: Reset after an upstream file addition in offline mode
    Given a basic setup with a puppet module "puppet-test" from "awesome"
    And the global option "branch" sets to "modulesync"
    And I successfully run `msync reset`
    Then the file "modules/awesome/puppet-test/hello" should not exist
    When the puppet module "puppet-test" from "awesome" has a branch named "execute"
    And the puppet module "puppet-test" from "awesome" has, in branch "execute", a file named "hello" with:
    """
    Hello
    """
    When I successfully run `msync reset --offline`
    Then the file "modules/awesome/puppet-test/hello" should not exist

  Scenario: Reset to a specified branch
    Given a basic setup with a puppet module "puppet-test" from "awesome"
    And the global option "branch" sets to "modulesync"
    When the puppet module "puppet-test" from "awesome" has a branch named "other-branch"
    And the puppet module "puppet-test" from "awesome" has, in branch "other-branch", a file named "hello" with:
    """
    Hello
    """
    And I successfully run `msync reset`
    Then the file "modules/awesome/puppet-test/hello" should not exist
    When I successfully run `msync reset --verbose --source-branch origin/other-branch`
    And the output should contain "Hard-resetting any local changes to repository in 'modules/awesome/puppet-test' from branch 'origin/other-branch'"
    Then the file "modules/awesome/puppet-test/hello" should exist
