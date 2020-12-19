require_relative '../../spec/helpers/faker/puppet_module_remote_repo'

Given 'a mocked git configuration' do
  steps %(
    Given a mocked home directory
    And I run `git config --global user.name Aruba`
    And I run `git config --global user.email aruba@example.com`
  )
end

Given 'a puppet module {string} from {string}' do |name, namespace|
  pmrr = ModuleSync::Faker::PuppetModuleRemoteRepo.new(name, namespace)
  pmrr.populate
end

Given 'a git_base option appended to "modulesync.yml" for local tests' do
  File.write "#{Aruba.config.working_directory}/modulesync.yml", "\ngit_base: #{ModuleSync::Faker::PuppetModuleRemoteRepo.git_base}", mode: 'a'
end

Given 'the puppet module {string} from {string} is read-only' do |name, namespace|
  pmrr = ModuleSync::Faker::PuppetModuleRemoteRepo.new(name, namespace)
  pmrr.read_only = true
end

Then 'the puppet module {string} from {string} should have no commits between {string} and {string}' do |name, namespace, commit1, commit2|
  pmrr = ModuleSync::Faker::PuppetModuleRemoteRepo.new(name, namespace)
  expect(pmrr.commit_count_between(commit1, commit2)).to eq 0
end

Then 'the puppet module {string} from {string} should have( only) {int} commit(s) made by {string}' do |name, namespace, commit_count, author|
  pmrr = ModuleSync::Faker::PuppetModuleRemoteRepo.new(name, namespace)
  expect(pmrr.commit_count_by(author)).to eq commit_count
end

Then 'the puppet module {string} from {string} should have( only) {int} commit(s) made by {string} in branch {string}' do |name, namespace, commit_count, author, branch|
  pmrr = ModuleSync::Faker::PuppetModuleRemoteRepo.new(name, namespace)
  expect(pmrr.commit_count_by(author, branch)).to eq commit_count
end

Then 'the puppet module {string} from {string} should have no commits made by {string}' do |name, namespace, author|
  step "the puppet module \"#{name}\" from \"#{namespace}\" should have 0 commits made by \"#{author}\""
end

Given 'the puppet module {string} from {string} has a file named {string} with:' do |name, namespace, filename, content|
  pmrr = ModuleSync::Faker::PuppetModuleRemoteRepo.new(name, namespace)
  pmrr.add_file(filename, content)
end

Then 'the puppet module {string} from {string} should have a branch {string} with a file named {string} which contains:' do |name, namespace, branch, filename, content|
  pmrr = ModuleSync::Faker::PuppetModuleRemoteRepo.new(name, namespace)
  expect(pmrr.read_file(filename, branch)).to include(content)
end

Given 'the puppet module {string} from {string} has the default branch named {string}' do |name, namespace, default_branch|
  pmrr = ModuleSync::Faker::PuppetModuleRemoteRepo.new(name, namespace)
  pmrr.default_branch = default_branch
end

Given 'a remote module repository' do
  steps %(
    Given a directory named "sources"
    And I run `git clone https://github.com/maestrodev/puppet-test sources/puppet-test`
    And a file named "managed_modules.yml" with:
      """
      ---
        - puppet-test
      """
  )
  write_file('modulesync.yml', <<~CONFIG)
    ---
    namespace: sources
    git_base: file://#{expand_path('.')}/
    CONFIG
end

Given Regexp.new(/a remote module repository with "(.+?)" as the default branch/) do |branch|
  steps %(
    Given a directory named "sources"
    And I run `git clone --mirror https://github.com/maestrodev/puppet-test sources/puppet-test`
    And a file named "managed_modules.yml" with:
      """
      ---
        - puppet-test
      """
  )
  write_file('modulesync.yml', <<~CONFIG)
    ---
    namespace: sources
    git_base: file://#{expand_path('.')}/
    CONFIG

  cd('sources/puppet-test') do
    steps %(
      And I run `git branch -M master #{branch}`
      And I run `git symbolic-ref HEAD refs/heads/#{branch}`
    )
  end
end
