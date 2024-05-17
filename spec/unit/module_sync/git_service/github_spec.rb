require 'spec_helper'

require 'modulesync/git_service/github'

describe ModuleSync::GitService::GitHub do
  context '::open_pull_request' do
    before do
      @client = double
      allow(Octokit::Client).to receive(:new).and_return(@client)
      @it = described_class.new('test', 'https://api.github.com')
    end

    let(:args) do
      {
        repo_path: 'test/modulesync',
        namespace: 'test',
        title: 'Test PR is submitted',
        message: 'Hello world',
        source_branch: 'test',
        target_branch: 'master',
        labels: labels,
        noop: false,
      }
    end

    let(:labels) { [] }

    it 'submits PR when --pr is set' do
      allow(@client).to receive(:pull_requests)
        .with(args[:repo_path],
              state: 'open',
              base: 'master',
              head: "#{args[:namespace]}:#{args[:source_branch]}").and_return([])
      expect(@client).to receive(:create_pull_request)
        .with(args[:repo_path],
              'master',
              args[:source_branch],
              args[:title],
              args[:message]).and_return({ 'html_url' => 'http://example.com/pulls/22' })
      expect { @it.open_pull_request(**args) }.to output(/Submitted PR/).to_stdout
    end

    it 'skips submitting PR if one has already been issued' do
      pr = {
        'title' => 'Test title',
        'html_url' => 'https://example.com/pulls/44',
        'number' => '44',
      }

      expect(@client).to receive(:pull_requests)
        .with(args[:repo_path],
              state: 'open',
              base: 'master',
              head: "#{args[:namespace]}:#{args[:source_branch]}").and_return([pr])
      expect { @it.open_pull_request(**args) }.to output("Skipped! 1 PRs found for branch 'test'\n").to_stdout
    end

    context 'when labels are set' do
      let(:labels) { %w[HELLO WORLD] }

      it 'adds labels to PR' do
        allow(@client).to receive(:create_pull_request).and_return({ 'html_url' => 'http://example.com/pulls/22',
                                                                     'number' => '44', })
        allow(@client).to receive(:pull_requests)
          .with(args[:repo_path],
                state: 'open',
                base: 'master',
                head: "#{args[:namespace]}:#{args[:source_branch]}").and_return([])
        expect(@client).to receive(:add_labels_to_an_issue)
          .with(args[:repo_path],
                '44',
                %w[HELLO WORLD])
        expect do
          @it.open_pull_request(**args)
        end.to output(/Attaching the following labels to PR 44: HELLO, WORLD/).to_stdout
      end
    end
  end
end
