Feature: execute
  Use ModuleSync to execute a custom script on each repositories

  Scenario: Cloning sourcecodes before running command when modules/ dir is empty
    Given a basic setup with a puppet module "puppet-test" from "awesome"
    Then the file "modules/awesome/puppet-test/metadata.json" should not exist
    When I successfully run `msync exec --verbose /bin/true`
    Then the output should contain "Cloning from 'file://"
    And the file "modules/awesome/puppet-test/metadata.json" should exist

  @no-clobber
  Scenario: No clones before running command when sourcecode have already been cloned
    Then the file "modules/awesome/puppet-test/metadata.json" should exist
    When I successfully run `msync exec --verbose /bin/true`
    Then the output should not contain "Cloning from 'file://"
