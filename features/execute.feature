Feature: execute
  Use ModuleSync to execute a custom script on a specified branch for each repos and optionaly push and submit a PR/MR

  Scenario: Running command without required 'branch' option
    When I run `msync exec`
    Then the output should match /^No value provided for required options '--branch'$/

  Scenario: Cloning modules before running command when modules/ dir is empty
    Given a basic setup with a puppet module "puppet-test" from "awesome"
    Then the file "modules/awesome/puppet-test/metadata.json" should not exist
    When I run `msync exec -b master /bin/true`
    Then the exit status should be 0
    And the file "modules/awesome/puppet-test/metadata.json" should exist

  @no-clobber
  Scenario: Hard-reset on specified branch before running command when modules have already been cloned
    Given the file "modules/awesome/puppet-test/metadata.json" should exist
    And the file "modules/awesome/puppet-test/hello" should not exist
    And the puppet module "puppet-test" from "awesome" have a branch "execute"
    And the puppet module "puppet-test" from "awesome" have a file named "hello" on branch "execute" with:
      """
      Hello
      """
    When I run `msync exec -b master --reset-hard origin/execute /bin/true`
    And the file "modules/awesome/puppet-test/hello" should exist
