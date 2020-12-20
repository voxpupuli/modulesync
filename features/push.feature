Feature: push
  Use ModuleSync to push a specified branch from each repos and optionaly submit a PR/MR

  Scenario: When 'branch' option is missing
    When I run `msync push`
    Then the output should match /^No value provided for required options '--branch'$/

  Scenario: Report the need to clone repositories if puppet module have not been fetch before
    Given a basic setup with a puppet module "puppet-test" from "awesome"
    When I run `msync push --branch hello`
    Then the exit status should be 1
    And the stderr should contain:
      """
      Repository must be locally available before trying to push
      """
