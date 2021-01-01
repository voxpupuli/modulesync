require 'spec_helper'

require 'modulesync/git_service/github'

describe ModuleSync::GitService::GitHub do
  context '::open_pull_request' do
    before(:each) do
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
      allow(Octokit::Client).to receive(:new).and_return(@client)
      @it = ModuleSync::GitService::GitHub.new('test', 'https://api.github.com')
    end

    it 'submits PR when --pr is set' do
      allow(@client).to receive(:pull_requests)
        .with(@git_repo,
              :state => 'open',
              :base => 'master',
              :head => "#{@namespace}:#{@options[:branch]}"
             ).and_return([])
      expect(@client).to receive(:create_pull_request)
        .with(@git_repo,
              'master',
              @options[:branch],
              @options[:pr_title],
              @options[:message]
             ).and_return({"html_url" => "http://example.com/pulls/22"})
      expect { @it.open_pull_request(@namespace, @repo_name, @options) }.to output(/Submitted PR/).to_stdout
    end

    it 'skips submitting PR if one has already been issued' do
      pr = {
        "title" => "Test title",
        "html_url" => "https://example.com/pulls/44",
        "number" => "44"
      }

      expect(@client).to receive(:pull_requests)
        .with(@git_repo,
              :state => 'open',
              :base => 'master',
              :head => "#{@namespace}:#{@options[:branch]}"
             ).and_return([pr])
      expect { @it.open_pull_request(@namespace, @repo_name, @options) }.to output(/Skipped! 1 PRs found for branch test/).to_stdout
    end

    context 'when labels are set' do
      it 'adds labels to PR' do
        @options[:pr_labels] = "HELLO,WORLD"

        allow(@client).to receive(:create_pull_request).and_return({"html_url" => "http://example.com/pulls/22", "number" => "44"})
        allow(@client).to receive(:pull_requests)
          .with(@git_repo,
                :state => 'open',
                :base => 'master',
                :head => "#{@namespace}:#{@options[:branch]}"
               ).and_return([])

        expect(@client).to receive(:add_labels_to_an_issue)
          .with(@git_repo,
                "44",
                ["HELLO", "WORLD"]
               )
        expect { @it.open_pull_request(@namespace, @repo_name, @options) }.to output(/Attaching the following labels to PR 44: HELLO, WORLD/).to_stdout
      end
    end
  end
end
