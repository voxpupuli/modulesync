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
    Then the file "modules/awesome/puppet-test/metadata.json" should exist
    When I successfully run `msync exec --verbose /bin/true`
    Then the stdout should not contain "Cloning from 'file://"

  @no-clobber
  Scenario: When command run fails, fail fast if option defined
    When I run `msync exec --verbose --fail-fast -- /bin/false`
    Then the exit status should be 1
    And the stderr should contain:
    """
    Command execution failed
    """

  @no-clobber
  Scenario: When command run fails, run all and summarize errors if option fail-fast is not set
    When I run `msync exec --verbose --no-fail-fast -- /bin/false`
    Then the exit status should be 1
    And the stderr should contain:
    """
    Error(s) during `execute` command:
      *
    """

  Scenario: Show fail-fast default value in help
    When I successfully run `msync help exec`
    Then the stdout should contain:
    """
          [--fail-fast], [--no-fail-fast], [--skip-fail-fast]                 # Abort the run after a command execution failure
                                                                              # Default: true
    """

  Scenario: Override fail-fast default value using config file
    Given the global option "fail_fast" sets to "false"
    When I successfully run `msync help exec`
    Then the stdout should contain:
    """
    [--fail-fast], [--no-fail-fast], [--skip-fail-fast]                 # Abort the run after a command execution failure
    """
    # NOTE: It seems there is a Thor bug here: default value is missing in help when sets to 'false'
