require 'spec_helper'
require 'modulesync/pr/gitlab'

describe ModuleSync::PR::GitLab do
  context '::manage' do
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
      allow(Gitlab::Client).to receive(:new).and_return(@client)
      @it = ModuleSync::PR::GitLab.new('test', 'https://gitlab.com/api/v4')
    end

    it 'submits MR when --pr is set' do
      allow(@client).to receive(:merge_requests)
        .with(@git_repo,
              :state => 'opened',
              :source_branch => "#{@namespace}:#{@options[:branch]}",
              :target_branch => 'master',
             ).and_return([])

      expect(@client).to receive(:create_merge_request)
        .with(@git_repo,
              @options[:pr_title],
              :labels => [],
              :source_branch => @options[:branch],
              :target_branch => 'master',
             ).and_return({"html_url" => "http://example.com/pulls/22"})

      expect { @it.manage(@namespace, @repo_name, @options) }.to output(/Submitted MR/).to_stdout
    end

    it 'skips submitting MR if one has already been issued' do
      mr = {
        "title" => "Test title",
        "html_url" => "https://example.com/pulls/44",
        "iid" => "44"
      }

      expect(@client).to receive(:merge_requests)
        .with(@git_repo,
              :state => 'opened',
              :source_branch => "#{@namespace}:#{@options[:branch]}",
              :target_branch => 'master',
             ).and_return([mr])

      expect { @it.manage(@namespace, @repo_name, @options) }.to output(/Skipped! 1 MRs found for branch test/).to_stdout
    end

    it 'adds labels to MR when --pr-labels is set' do
      @options[:pr_labels] = "HELLO,WORLD"
      mr = double()
      allow(mr).to receive(:iid).and_return("42")

      expect(@client).to receive(:create_merge_request)
        .with(@git_repo,
              @options[:pr_title],
              :labels => ["HELLO", "WORLD"],
              :source_branch => @options[:branch],
              :target_branch => 'master',
             ).and_return(mr)

      allow(@client).to receive(:merge_requests)
        .with(@git_repo,
              :state => 'opened',
              :source_branch => "#{@namespace}:#{@options[:branch]}",
              :target_branch => 'master',
             ).and_return([])

      expect { @it.manage(@namespace, @repo_name, @options) }.to output(/Attached the following labels to MR 42: HELLO, WORLD/).to_stdout
    end
  end
end
