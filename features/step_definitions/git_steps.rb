require_relative '../../spec/helpers/faker/puppet_module_remote_repo'

Given 'a basic setup with a puppet module {string} from {string}' do |name, namespace|
  steps %(
    Given a mocked git configuration
    And a puppet module "#{name}" from "#{namespace}"
    And a file named "managed_modules.yml" with:
      """
      ---
        - #{name}
      """
    And a file named "modulesync.yml" with:
      """
      ---
      namespace: #{namespace}
      """
    And a git_base option appended to "modulesync.yml" for local tests
  )
end

Given 'a mocked git configuration' do
  steps %(
    Given a mocked home directory
    And I run `git config --global user.name Aruba`
    And I run `git config --global user.email aruba@example.com`
  )
end

Given 'a puppet module {string} from {string}' do |name, namespace|
  pmrr = Faker::PuppetModuleRemoteRepo.new(name, namespace)
  pmrr.populate
end

Given 'a git_base option appended to "modulesync.yml" for local tests' do
  File.write "#{Aruba.config.working_directory}/modulesync.yml", "\ngit_base: #{Faker::PuppetModuleRemoteRepo.git_base}", mode: 'a'
end

Given 'the puppet module {string} from {string} is read-only' do |name, namespace|
  pmrr = Faker::PuppetModuleRemoteRepo.new(name, namespace)
  pmrr.read_only = true
end

Then 'the puppet module {string} from {string} have no commit between {string} and {string}' do |name, namespace, commit1, commit2|
  pmrr = Faker::PuppetModuleRemoteRepo.new(name, namespace)
  expect(pmrr.commit_count_between(commit1, commit2)).to eq 0
end

Then 'the puppet module {string} from {string} have( only) {int} commit(s) made by {string}' do |name, namespace, commit_count, author|
  pmrr = Faker::PuppetModuleRemoteRepo.new(name, namespace)
  expect(pmrr.commit_count_by(author)).to eq commit_count
end

Then 'the puppet module {string} from {string} have( only) {int} commit(s) made by {string} in branch {string}' do |name, namespace, commit_count, author, branch|
  pmrr = Faker::PuppetModuleRemoteRepo.new(name, namespace)
  expect(pmrr.commit_count_by(author, branch)).to eq commit_count
end

Then 'the puppet module {string} from {string} have no commit made by {string}' do |name, namespace, author|
  step "the puppet module \"#{name}\" from \"#{namespace}\" have 0 commit made by \"#{author}\""
end

Given 'the puppet module {string} from {string} have a file named {string} with:' do |name, namespace, filename, content|
  pmrr = Faker::PuppetModuleRemoteRepo.new(name, namespace)
  pmrr.add_file(filename, content)
end

Then 'the puppet module {string} from {string} should have a branch {string} with a file named {string} which contains:' do |name, namespace, branch, filename, content|
  pmrr = Faker::PuppetModuleRemoteRepo.new(name, namespace)
  expect(pmrr.read_file(filename, branch)).to include(content)
end

Given 'the puppet module {string} from {string} have the default branch named {string}' do |name, namespace, default_branch|
  pmrr = Faker::PuppetModuleRemoteRepo.new(name, namespace)
  pmrr.default_branch = default_branch
end
