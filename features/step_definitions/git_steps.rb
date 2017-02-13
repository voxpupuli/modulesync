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
  write_file('modulesync.yml', <<-EOS)
---
  namespace: sources
  git_base: file://#{expand_path('.')}/
  EOS
end
