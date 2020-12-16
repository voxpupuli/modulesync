Feature: CLI
  ModuleSync needs to have a robust command line interface

  Scenario: When passing no arguments to the msync command
    When I run `msync`
    And the output should match /Commands:/

  Scenario: When passing invalid arguments to the msync update command
    When I run `msync update`
    And the output should match /No value provided for required option/

  Scenario: When passing invalid arguments to the msync hook command
    When I run `msync hook`
    And the output should match /Commands:/

  Scenario: When running the help subcommand
    When I run `msync help`
    And the output should match /Commands:/

  Scenario: When overriding a setting from the config file on the command line
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And a directory named "moduleroot"
    When I run `msync update --noop --namespace fakenamespace`
    Then the exit status should be 0
    And the stdout should contain:
      """
      Syncing 'fakenamespace/puppet-test'
      """
