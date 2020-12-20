Feature: hook
  ModuleSync needs to update git pre-push hooks

  Scenario: Activating a hook
    Given a directory named ".git/hooks"
    When I run `msync hook activate`
    Then the exit status should be 0
    And the file named ".git/hooks/pre-push" should contain "bash"

  Scenario: Deactivating a hook
    Given a file named ".git/hooks/pre-push" with:
      """
      git hook
      """
    When I run `msync hook deactivate`
    Then the exit status should be 0
    Then the file ".git/hooks/pre-push" should not exist

  Scenario: Activating a hook with arguments
    Given a directory named ".git/hooks"
    When I run `msync hook activate -a '--foo bar --baz quux' -b master`
    Then the exit status should be 0
    And the file named ".git/hooks/pre-push" should contain:
      """
      "$message" -n puppetlabs -b master --foo bar --baz quux
      """
