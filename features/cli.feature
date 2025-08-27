Feature: CLI
  ModuleSync needs to have a robust command line interface

  Scenario: When passing no arguments to the msync command
    When I run `msync`
    And the output should match /Commands:/
    Then the exit status should be 1

  Scenario: When passing invalid arguments to the msync update command
    When I run `msync update`
    And the output should match /No value provided for required option/
    Then the exit status should be 1

  Scenario: When passing invalid arguments to the msync hook command
    When I run `msync hook`
    And the output should match /Commands:/
    Then the exit status should be 1

  Scenario: When running the help command
    When I successfully run `msync help`
    Then the output should match /Commands:/

  Scenario: Use --help options on subcommand should show subcommand help
    When I successfully run `msync clone --help`
    Then the output should contain:
    """
    Usage:
      msync clone
    """

  Scenario: When overriding a setting from the config file on the command line
    Given a puppet module "puppet-test" from "fakenamespace"
    And a file named "managed_modules.yml" with:
      """
      ---
        - puppet-test
      """
    And a file named "modulesync.yml" with:
      """
      ---
      namespace: default
      """
    And a git_base option appended to "modulesync.yml" for local tests
    And a directory named "moduleroot"
    When I successfully run `msync update --verbose --noop --namespace fakenamespace --branch command-line-branch`
    Then the output should contain:
      """
      Creating new branch command-line-branch from master
      """
