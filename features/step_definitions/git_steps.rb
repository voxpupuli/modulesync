Given 'a mocked git configuration' do
  steps %(
    Given a mocked home directory
    And I run `git config --global user.name Test`
    And I run `git config --global user.email test@example.com`
  )
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
  write_file('modulesync.yml', <<-CONFIG)
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
  write_file('modulesync.yml', <<-CONFIG)
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
