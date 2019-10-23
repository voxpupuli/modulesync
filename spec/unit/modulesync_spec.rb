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
      @options = {
        :pr => true,
        :pr_title => 'Test PR is submitted',
        :branch => 'test',
        :message => 'Hello world',
        :pr_auto_merge => false,
      }

      @client = double()
    end

    it 'rasies an error when GITHUB_TOKEN not set for PRs' do
      stub_const('GITHUB_TOKEN', '')
      options = {:pr => true, :skip_broken => false}

      expect { ModuleSync.manage_pr(nil, options) }.to raise_error(RuntimeError).and output(/GITHUB_TOKEN/).to_stderr
    end

    it 'submits PR when --pr is set' do
      allow(Octokit::Client).to receive(:new).and_return(@client)

      expect(@client).to receive(:create_pull_request).with(@git_repo, 'master', @options[:branch], @options[:pr_title], @options[:message]).and_return({"html_url" => "http://example.com/pulls/22"})
      expect { ModuleSync.manage_pr(@git_repo, @options) }.to output(/PR created at/).to_stdout
    end

    it 'adds labels to PR when --pr-labels is set' do
      @options[:pr_labels] = "HELLO,WORLD"
      allow(Octokit::Client).to receive(:new).and_return(@client)

      allow(@client).to receive(:create_pull_request).and_return({"html_url" => "http://example.com/pulls/22", "number" => "44"})

      expect(@client).to receive(:add_labels_to_an_issue).with(@git_repo, "44", ["HELLO", "WORLD"])
      expect { ModuleSync.manage_pr(@git_repo, @options) }.to output(/Attaching the following labels to PR 44: HELLO, WORLD/).to_stdout
    end

    it 'auto-merges the PR when --pr-auto-merge is set' do
      @options[:pr_auto_merge] = true
      allow(Octokit::Client).to receive(:new).and_return(@client)

      allow(@client).to receive(:create_pull_request).and_return({"html_url" => "http://example.com/pulls/22", "number" => "44"})

      expect(@client).to receive(:merge_pull_request).with(@git_repo, "44", "Auto-merge modulesync generated PR 44")
      expect { ModuleSync.manage_pr(@git_repo, @options) }.to output(/Automatically merged PR 44/).to_stdout
    end
  end
end
