# frozen_string_literal: true

require 'spec_helper'

require 'modulesync/git_service/gitlab'

describe ModuleSync::GitService::GitLab do
  context '::open_pull_request' do
    before do
      @client = double
      allow(Gitlab::Client).to receive(:new).and_return(@client)
      @it = described_class.new('test', 'https://gitlab.com/api/v4')
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
              state: 'opened',
              source_branch: args[:source_branch],
              target_branch: 'master').and_return([])

      expect(@client).to receive(:create_merge_request)
        .with(args[:repo_path],
              args[:title],
              labels: [],
              source_branch: args[:source_branch],
              target_branch: 'master').and_return({ 'html_url' => 'http://example.com/pulls/22' })

      expect { @it.open_pull_request(**args) }.to output(/Submitted MR/).to_stdout
    end

    it 'updates the title if an existing MR has a different title' do
      mr = {
        'title' => 'Test title',
        'html_url' => 'https://example.com/pulls/44',
        'iid' => '44',
      }

      expect(@client).to receive(:merge_requests)
        .with(args[:repo_path],
              state: 'opened',
              source_branch: args[:source_branch],
              target_branch: 'master').and_return([mr])
      expect(@client).to receive(:update_merge_request)
        .with(args[:repo_path], mr['iid'], title: args[:title])
      expect { @it.open_pull_request(**args) }
        .to output("Updated title of existing MR !44 to 'Test MR is submitted'\n").to_stdout
    end

    it 'skips updating an existing MR if its title is unchanged' do
      mr = {
        'title' => args[:title],
        'html_url' => 'https://example.com/pulls/44',
        'iid' => '44',
      }

      expect(@client).to receive(:merge_requests)
        .with(args[:repo_path],
              state: 'opened',
              source_branch: args[:source_branch],
              target_branch: 'master').and_return([mr])
      expect(@client).not_to receive(:update_merge_request)
      expect { @it.open_pull_request(**args) }
        .to output("Skipped! 1 MRs found for branch 'test'\n" \
                   "Skipped! Existing MR !44 already has title 'Test MR is submitted'\n").to_stdout
    end

    context 'when labels are set' do
      let(:labels) { %w[HELLO WORLD] }

      it 'adds labels to MR' do
        mr = double
        allow(mr).to receive(:iid).and_return('42')

        expect(@client).to receive(:create_merge_request)
          .with(args[:repo_path],
                args[:title],
                labels: %w[HELLO WORLD],
                source_branch: args[:source_branch],
                target_branch: 'master').and_return(mr)

        allow(@client).to receive(:merge_requests)
          .with(args[:repo_path],
                state: 'opened',
                source_branch: args[:source_branch],
                target_branch: 'master').and_return([])

        expect do
          @it.open_pull_request(**args)
        end.to output(/Attached the following labels to MR 42: HELLO, WORLD/).to_stdout
      end
    end
  end
end
