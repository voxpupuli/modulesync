Feature: Update using a `.sync.yml` file
  ModuleSync needs to apply templates according to `.sync.yml` content

  Scenario: Updating a module with a .sync.yml file
    Given a basic setup with a puppet module "puppet-test" from "fakenamespace"
    And a file named "config_defaults.yml" with:
      """
      ---
      :global:
        variable: 'global'
      template_with_specific_config:
        variable: 'specific'
      """
    And a file named "moduleroot/template_with_specific_config.erb" with:
      """
      ---
      <%= @configs['variable'] %>
      """
    And a file named "moduleroot/template_with_only_global_config.erb" with:
      """
      ---
      <%= @configs['variable'] %>
      """
    And the puppet module "puppet-test" from "fakenamespace" has a branch named "target"
    And the puppet module "puppet-test" from "fakenamespace" has, in branch "target", a file named ".sync.yml" with:
      """
      ---
      :global:
        variable: 'overwritten by globally defined value in .sync.yml'
      template_with_specific_config:
        variable: 'overwritten by file-specific defined value in .sync.yml'
      """
    When I successfully run `msync update --message 'Apply ModuleSync templates to target source code' --branch 'target'`
    Then the file named "modules/fakenamespace/puppet-test/template_with_specific_config" should contain:
      """
      overwritten by file-specific defined value in .sync.yml
      """
    And the puppet module "puppet-test" from "fakenamespace" should have 1 commit made by "Aruba"
    When the puppet module "puppet-test" from "fakenamespace" has, in branch "target", a file named ".sync.yml" with:
      """
      ---
      :global:
        variable: 'overwritten by globally defined value in .sync.yml'
      template_with_specific_config:
        variable: 'overwritten by newly file-specific defined value in .sync.yml'
      """
    And I successfully run `msync update --message 'Apply ModuleSync templates to target source code' --branch 'target'`
    Then the file named "modules/fakenamespace/puppet-test/template_with_specific_config" should contain:
      """
      overwritten by newly file-specific defined value in .sync.yml
      """
    And the puppet module "puppet-test" from "fakenamespace" should have 2 commits made by "Aruba"
