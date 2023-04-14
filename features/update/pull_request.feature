Feature: Create a pull-request/merge-request after update

  Scenario: Run update in no-op mode and ask for GitHub PR
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And a file named "managed_modules.yml" with:
      """
      ---
      puppet-test:
        github: {}
      """
    And I set the environment variables to:
      | variable        | value                    |
      | GITHUB_TOKEN    | foobar                   |
      | GITHUB_BASE_URL | https://github.example.com |
    And a file named "config_defaults.yml" with:
      """
      ---
      test:
        name: aruba
      """
    And a file named "moduleroot/test.erb" with:
      """
      <%= @configs['name'] %>
      """
    When I successfully run `msync update --noop --branch managed_update --pr`
    Then the output should contain "Would submit PR "
    And the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"

  Scenario: Run update in no-op mode and ask for GitLab MR
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And a file named "managed_modules.yml" with:
      """
      ---
      puppet-test:
        gitlab:
          base_url: 'https://gitlab.example.com'
      """
    And I set the environment variables to:
      | variable     | value  |
      | GITLAB_TOKEN | foobar |
    And a file named "config_defaults.yml" with:
      """
      ---
      test:
        name: aruba
      """
    And a file named "moduleroot/test.erb" with:
      """
      <%= @configs['name'] %>
      """
    When I successfully run `msync update --noop --branch managed_update --pr`
    Then the output should contain "Would submit MR "
    And the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"

  Scenario: Run update without changes in no-op mode and ask for GitLab MR
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And a directory named "moduleroot"
    And a file named "managed_modules.yml" with:
      """
      ---
      puppet-test:
        gitlab:
          base_url: 'https://gitlab.example.com'
      """
    And I set the environment variables to:
      | variable     | value  |
      | GITLAB_TOKEN | foobar |
    When I successfully run `msync update --noop --branch managed_update --pr`
    Then the output should not contain "Would submit MR "
    And the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"

  Scenario: Ask for PR without credentials
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And a file named "managed_modules.yml" with:
      """
      ---
      puppet-test:
        gitlab:
          base_url: https://gitlab.example.com
      """
    And a file named "config_defaults.yml" with:
      """
      ---
      test:
        name: aruba
      """
    And a file named "moduleroot/test.erb" with:
      """
      <%= @configs['name'] %>
      """
    When I run `msync update --noop --pr`
    Then the stderr should contain "A token is required to use services from gitlab"
    And the exit status should be 1
    And the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"

  Scenario: Ask for PR/MR with modules from GitHub and from GitLab
    Given a basic setup with a puppet module "puppet-github" from "fakenamespace"
    And a basic setup with a puppet module "puppet-gitlab" from "fakenamespace"
    And a file named "managed_modules.yml" with:
      """
      ---
      puppet-github:
        github:
          base_url: https://github.example.com
          token: 'secret'
      puppet-gitlab:
        gitlab:
          base_url: https://gitlab.example.com
          token: 'secret'
      """
    And a file named "config_defaults.yml" with:
      """
      ---
      test:
        name: aruba
      """
    And a file named "moduleroot/test.erb" with:
      """
      <%= @configs['name'] %>
      """
    When I successfully run `msync update --noop --branch managed_update --pr`
    Then the output should contain "Would submit PR "
    And the output should contain "Would submit MR "
    And the puppet module "puppet-github" from "fakenamespace" should have no commits made by "Aruba"
    And the puppet module "puppet-gitlab" from "fakenamespace" should have no commits made by "Aruba"

  Scenario: Ask for PR with same source and target branch
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And a file named "managed_modules.yml" with:
      """
      ---
      puppet-test:
        gitlab:
          token: 'secret'
          base_url: 'https://gitlab.example.com'
      """
    And a file named "config_defaults.yml" with:
      """
      ---
      test:
        name: aruba
      """
    And a file named "moduleroot/test.erb" with:
      """
      <%= @configs['name'] %>
      """
    When I run `msync update --noop --branch managed_update --pr --pr-target-branch managed_update`
    Then the stderr should contain "Unable to open a pull request with the same source and target branch: 'managed_update'"
    And the exit status should be 1
    And the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"

  Scenario: Ask for PR with the default branch as source and target
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And the puppet module "puppet-test" from "fakenamespace" has the default branch named "custom_default_branch"
    And a file named "managed_modules.yml" with:
      """
      ---
      puppet-test:
        github:
          token: 'secret'
          base_url: 'https://gitlab.example.com'
      """
    And a file named "config_defaults.yml" with:
      """
      ---
      test:
        name: aruba
      """
    And a file named "moduleroot/test.erb" with:
      """
      <%= @configs['name'] %>
      """
    And a directory named "moduleroot"
    When I run `msync update --noop --pr`
    Then the stderr should contain "Unable to open a pull request with the same source and target branch: 'custom_default_branch'"
    And the exit status should be 1
    And the puppet module "puppet-test" from "fakenamespace" should have no commits made by "Aruba"
