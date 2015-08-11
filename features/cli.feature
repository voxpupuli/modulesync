Feature: CLI
  ModuleSync needs to have a robust command line interface

  Scenario: When passing no arguments to the msync command
    When I run `msync`
    Then the output should match /Commands:/

  Scenario: When passing invalid arguments to the msync update command
    When I run `msync update`
    Then the output should match /No value provided for required options/

  Scenario: When passing invalid arguments to the msync hook command
    When I run `msync hook`
    Then the output should match /Commands:/

  Scenario: When running the help subcommand
    When I run `msync help`
    And the output should match /Commands:/

  Scenario: When running the version subcommand
    When I run `msync version`
    Then the exit status should be 0
    And the output should match /\d+\.\d+\.\d+/

  Scenario: When running the list files subcommand
    Given a file named "moduleroot/Rakefile" with:
      """
      This is a Rakefile.
      """
    When I run `msync list files`
    Then the exit status should be 0
    And the output should match /Rakefile/

  Scenario: When running the list modules subcommand
    Given a file named "managed_modules.yml" with:
      """
      ---
        - puppetlabs-stdlib
      """
    When I run `msync list modules`
    Then the exit status should be 0
    And the output should match /puppetlabs-stdlib/
