require 'spec_helper'

describe ModuleSync do
  context '::update' do
    it 'loads the managed modules from the specified :managed_modules_conf' do
      allow(ModuleSync).to receive(:find_template_files).and_return([])
      allow(ModuleSync::Util).to receive(:parse_config).with('./config_defaults.yml').and_return({})
      expect(ModuleSync).to receive(:managed_modules).with('./test_file.yml', nil, nil).and_return([])

      options = { managed_modules_conf: 'test_file.yml' }
      ModuleSync.update(options)
    end
  end

  context '::manage_pr' do
    before(:each) do
      stub_const('GITHUB_TOKEN', 'test')
      @git_repo = 'test/modulesync'
      @namespace, @repo_name = @git_repo.split('/')
      @options = {
        :pr => true,
        :pr_title => 'Test PR is submitted',
        :branch => 'test',
        :message => 'Hello world',
        :pr_auto_merge => false,
      }

      @client = double()
    end

    it 'skips submitting PR if one has already been issued' do
      allow(Octokit::Client).to receive(:new).and_return(@client)

      pr = {
        "title" => "Test title",
        "html_url" => "https://example.com/pulls/44",
        "number" => "44"
      }

      allow(@client).to receive(:pull_requests).with(@git_repo, :state => 'open', :base => 'master', :head => "#{@namespace}:#{@options[:branch]}").and_return([pr])
      expect { ModuleSync.manage_pr(@namespace, @repo_name, @options) }.to output(/Skipped! 1 PRs found for branch test/).to_stdout
    end
  end
end
