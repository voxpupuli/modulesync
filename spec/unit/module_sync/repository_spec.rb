# frozen_string_literal: true

require 'spec_helper'

describe ModuleSync::Repository do
  subject(:repository) do
    described_class.new(directory: '/tmp/example', remote: 'https://github.com/example/repository.git')
  end

  let(:remote_branches) do
    [
      instance_double(Git::Branch, name: 'main'),
      instance_double(Git::Branch, name: 'modulesync'),
    ]
  end
  let(:branches) { instance_double(Git::Branches, remote: remote_branches) }
  let(:log) { instance_double(Git::Log) }
  let(:git_lib) { instance_double(Git::Lib) }
  let(:git) { instance_double(Git::Base, branches: branches, lib: git_lib, log: log) }

  before do
    repository.instance_variable_set(:@git, git)
    ModuleSync.instance_variable_set(:@options, verbose: false)
  end

  it 'detects commits on a remote source branch that are missing from the target branch' do
    allow(log).to receive(:between).with('origin/main', 'origin/modulesync').and_return(log)
    allow(log).to receive(:execute).and_return([instance_double(Git::Object::Commit)])

    expect(repository.remote_branch_ahead?('modulesync', 'main')).to be true
  end

  it 'rejects a source branch that does not exist remotely' do
    remote_branches.pop

    expect(repository.remote_branch_ahead?('modulesync', 'main')).to be false
  end

  describe '#rebase_onto' do
    before do
      allow(git).to receive(:current_branch).and_return('modulesync')
    end

    it 'rebases the current branch onto the remote default branch' do
      expect(git_lib).to receive(:command).with('rebase', 'origin/main')

      repository.rebase_onto('main')
    end

    it 'does not rebase the default branch onto itself' do
      allow(git).to receive(:current_branch).and_return('main')
      expect(git_lib).not_to receive(:command)

      repository.rebase_onto('main')
    end

    it 'aborts and reports a failed rebase' do
      allow(git_lib).to receive(:command).with('rebase', 'origin/main').and_raise(Git::Error, 'merge conflict')
      expect(git_lib).to receive(:command).with('rebase', '--abort')

      expect { repository.rebase_onto('main') }
        .to raise_error(ModuleSync::Error, %r{Rebase onto origin/main failed and was aborted: merge conflict})
    end
  end

  describe '#prepare_workspace' do
    it 'fetches and rebases the selected branch onto the remote default branch when requested' do
      allow(Dir).to receive(:exist?).with('/tmp/example/.git').and_return(true)
      allow(Git).to receive(:default_branch).with('https://github.com/example/repository.git').and_return('main')
      allow(git).to receive(:current_branch).and_return('modulesync')
      expect(git).to receive(:fetch).with('origin', prune: true).ordered
      expect(git).to receive(:reset_hard).ordered
      expect(git).to receive(:pull).with('origin', 'modulesync').ordered
      expect(git_lib).to receive(:command).with('rebase', 'origin/main').ordered

      repository.prepare_workspace(branch: 'modulesync', operate_offline: false, rebase: true)
    end
  end
end
