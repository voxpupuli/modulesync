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

  context '::manage_module' do
    before(:each) do
      stub_const('GITHUB_TOKEN', '')
      ModuleSync::GLOBAL_DEFAULTS_KEY = 0
      @puppet_module = 'puppet'
      @module_options = 'module'
      @module_files = []
      @defaults = {}
      @options = {
        :namespace => 'test',
        :offline => false,
        :branch => 'test',
        :project_root => 'root',
        :git_base => 'base',
        :skip_broken => false,
        :pr => true
      }
    end

    describe "Raise Error" do
      it 'raises an error when neither GITHUB_TOKEN nor GITLAB_TOKEN are set for PRs' do
        allow(ModuleSync::Git).to receive(:pull)
        allow(ModuleSync::Git).to receive(:update).and_return(true)
        expect { ModuleSync.manage_module(@puppet_module, @module_files, @module_options, @defaults, @options) }.to raise_error(RuntimeError).and output(/GITHUB_TOKEN/).to_stderr
      end
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

    it 'submits PR when --pr is set' do
      allow(Octokit::Client).to receive(:new).and_return(@client)
      allow(@client).to receive(:pull_requests).with(@git_repo, :state => 'open', :base => 'master', :head => "#{@namespace}:#{@options[:branch]}").and_return([])
      expect(@client).to receive(:create_pull_request).with(@git_repo, 'master', @options[:branch], @options[:pr_title], @options[:message]).and_return({"html_url" => "http://example.com/pulls/22"})
      expect { ModuleSync.manage_pr(@namespace, @repo_name, @options) }.to output(/Submitted PR/).to_stdout
    end

    it 'skips submitting PR if one has already been issued' do
      allow(Octokit::Client).to receive(:new).and_return(@client)

      pr = {
        "title" => "Test title",
        "html_url" => "https://example.com/pulls/44",
        "number" => "44"
      }

      expect(@client).to receive(:pull_requests).with(@git_repo, :state => 'open', :base => 'master', :head => "#{@namespace}:#{@options[:branch]}").and_return([pr])
      expect { ModuleSync.manage_pr(@namespace, @repo_name, @options) }.to output(/Skipped! 1 PRs found for branch test/).to_stdout
    end

    it 'adds labels to PR when --pr-labels is set' do
      @options[:pr_labels] = "HELLO,WORLD"

      allow(Octokit::Client).to receive(:new).and_return(@client)
      allow(@client).to receive(:create_pull_request).and_return({"html_url" => "http://example.com/pulls/22", "number" => "44"})
      allow(@client).to receive(:pull_requests).with(@git_repo, :state => 'open', :base => 'master', :head => "#{@namespace}:#{@options[:branch]}").and_return([])

      expect(@client).to receive(:add_labels_to_an_issue).with(@git_repo, "44", ["HELLO", "WORLD"])
      expect { ModuleSync.manage_pr(@namespace, @repo_name, @options) }.to output(/Attaching the following labels to PR 44: HELLO, WORLD/).to_stdout
    end
  end
end
