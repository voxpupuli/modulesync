require 'spec_helper'

require 'modulesync/git_service/gitlab'

describe ModuleSync::GitService::GitLab do
  context '::open_pull_request' do
    before(:each) do
      @client = double()
      allow(Gitlab::Client).to receive(:new).and_return(@client)
      @it = ModuleSync::GitService::GitLab.new('test', 'https://gitlab.com/api/v4')
    end

    let(:args) do
      {
        repo_path: 'test/modulesync',
        namespace: 'test',
        title: 'Test MR is submitted',
        message: 'Hello world',
        source_branch: 'test',
        target_branch: 'master',
        labels: labels,
        noop: false,
      }
    end

    let(:labels) { [] }

    it 'submits MR when --pr is set' do
      allow(@client).to receive(:merge_requests)
        .with(args[:repo_path],
              :state => 'opened',
              :source_branch => "#{args[:namespace]}:#{args[:source_branch]}",
              :target_branch => 'master',
             ).and_return([])

      expect(@client).to receive(:create_merge_request)
        .with(args[:repo_path],
              args[:title],
              :labels => [],
              :source_branch => args[:source_branch],
              :target_branch => 'master',
             ).and_return({"html_url" => "http://example.com/pulls/22"})

      expect { @it.open_pull_request(**args) }.to output(/Submitted MR/).to_stdout
    end

    it 'skips submitting MR if one has already been issued' do
      mr = {
        "title" => "Test title",
        "html_url" => "https://example.com/pulls/44",
        "iid" => "44"
      }

      expect(@client).to receive(:merge_requests)
        .with(args[:repo_path],
              :state => 'opened',
              :source_branch => "#{args[:namespace]}:#{args[:source_branch]}",
              :target_branch => 'master',
             ).and_return([mr])

      expect { @it.open_pull_request(**args) }.to output("Skipped! 1 MRs found for branch 'test'\n").to_stdout
    end

    context 'when labels are set' do
      let(:labels) { %w{HELLO WORLD} }

      it 'adds labels to MR' do
        mr = double()
        allow(mr).to receive(:iid).and_return("42")

        expect(@client).to receive(:create_merge_request)
          .with(args[:repo_path],
                args[:title],
                :labels => ["HELLO", "WORLD"],
                :source_branch => args[:source_branch],
                :target_branch => 'master',
               ).and_return(mr)

        allow(@client).to receive(:merge_requests)
          .with(args[:repo_path],
                :state => 'opened',
                :source_branch => "#{args[:namespace]}:#{args[:source_branch]}",
                :target_branch => 'master',
               ).and_return([])

        expect { @it.open_pull_request(**args) }.to output(/Attached the following labels to MR 42: HELLO, WORLD/).to_stdout
      end
    end
  end
end
