Feature: execute
  Use ModuleSync to execute a custom script on each repositories

  Scenario: Cloning sourcecodes before running command when modules/ dir is empty
    Given a basic setup with a puppet module "puppet-test" from "awesome"
    Then the file "modules/awesome/puppet-test/metadata.json" should not exist
    When I successfully run `msync exec --verbose -- /bin/true`
    Then the stdout should contain "Cloning from 'file://"
    And the file "modules/awesome/puppet-test/metadata.json" should exist

  @no-clobber
  Scenario: No clones before running command when sourcecode have already been cloned
    Given a basic setup with a puppet module "puppet-test" from "awesome"
    And I successfully run `msync exec --verbose -- /bin/true`
    Then the file "modules/awesome/puppet-test/metadata.json" should exist
    When I successfully run `msync exec --verbose /bin/true`
    Then the stdout from "msync exec --verbose /bin/true" should not contain "Cloning from 'file://'"

  @no-clobber
  Scenario: When command run fails and using default skip_broken value
    Given a basic setup with a puppet module "puppet-test" from "awesome"
    And I successfully run `msync exec --verbose -- /bin/true`
    When I run `msync exec --verbose -- /bin/false`
    Then the exit status should be 1
    And the stderr should contain:
    """
    puppet-test: Command execution failed
    """

  @no-clobber
  Scenario: When command run fails and using skip_broken
    Given a basic setup with a puppet module "puppet-test" from "awesome"
    And I successfully run `msync exec --verbose -- /bin/true`
    When I run `msync exec --verbose -s -- /bin/false`
    Then the exit status should be 1
    And the stderr should contain:
    """
    Skipping 'puppet-test' as execute process failed
    """

  Scenario: Show preserved bundle env var.
    Given a basic setup with a puppet module "puppet-test" from "awesome"
    And I set the environment variables to:
      | variable   | value  |
      | BUNLE_PATH | /opt/msync/bundle |
    When I successfully run `msync exec --env BUNLE_PATH -- env`
    Then the stdout should contain:
    """
    BUNLE_PATH=/opt/msync/bundle
    """

  @no-clobber
  Scenario: Adding a new test file
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    When I successfully run `msync exec --noop -- touch test.yaml`
    Then the output should match:
      """
      Files added:
      test.yaml
      """
    And the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"

  Scenario: Modifying an existing file without commiting the change
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And the puppet module "puppet-test" from "fakenamespace" has a file named "README.md" with:
      """
      Hello world!
      """
    When I successfully run `msync exec --noop -- sed -i "$ a some text" README.md`
    Then the output should match:
      """
      Files changed:
      +diff --git a/README.md b/README.md
      """
    And the output should contain:
      """
      some text
      """
    And the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"

  Scenario: Modifying an existing file and committing the change
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And the puppet module "puppet-test" from "fakenamespace" has a file named "Gemfile" with:
      """
      source 'https://rubygems.org'
      """
    When I successfully run `msync exec -m "Update Gemfile" -r test -- sed -i "$ a some source" Gemfile`
    Then the puppet module "puppet-test" from "fakenamespace" should have only 1 commit made by "Aruba"
    And the puppet module "puppet-test" from "fakenamespace" should have 1 commit made by "Aruba" in branch "test"
    And the puppet module "puppet-test" from "fakenamespace" should have a branch "test" with a file named "Gemfile" which contains:
      """
      some source
      """
