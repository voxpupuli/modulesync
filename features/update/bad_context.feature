Feature: Run `msync update` without a good context

  Scenario: Run `msync update` without any module
    Given a directory named "moduleroot"
    When I run `msync update --message "In a bad context"`
    Then the exit status should be 1
    And the stderr should contain:
      """
      No modules found
      """

  Scenario: Run `msync update` without the "moduleroot" directory
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    When I run `msync update --message "In a bad context"`
    Then the exit status should be 1
    And the stderr should contain "moduleroot"

  Scenario: Run `msync update` without commit message
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And a directory named "moduleroot"
    When I run `msync update`
    Then the exit status should be 1
    And the stderr should contain:
      """
      No value provided for required option "--message"
      """
