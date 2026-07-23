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
      allow(log).to receive(:between).with('modulesync', 'origin/main').and_return(log)
      allow(log).to receive(:execute).and_return([instance_double(Git::Object::Commit)])
    end

    it 'rebases the current branch onto the remote default branch' do
      expect(git_lib).to receive(:send).with(:command, 'rebase', 'origin/main')

      repository.rebase_onto('main')
    end

    it 'does not rebase the default branch onto itself' do
      allow(git).to receive(:current_branch).and_return('main')
      expect(git_lib).not_to receive(:send)

      repository.rebase_onto('main')
    end

    it 'does not rebase a branch that already contains the remote default branch' do
      allow(log).to receive(:execute).and_return([])
      expect(git_lib).not_to receive(:send)

      repository.rebase_onto('main')
    end

    it 'aborts and reports a failed rebase' do
      allow(git_lib).to receive(:send).with(:command, 'rebase', 'origin/main').and_raise(Git::Error, 'merge conflict')
      expect(git_lib).to receive(:send).with(:command, 'rebase', '--abort')

      expect { repository.rebase_onto('main') }
        .to raise_error(ModuleSync::Error, %r{Rebase onto origin/main failed and was aborted: merge conflict})
    end
  end

  describe '#prepare_workspace' do
    it 'fetches and rebases the selected branch onto the remote default branch when requested' do
      allow(Dir).to receive(:exist?).with('/tmp/example/.git').and_return(true)
      allow(Git).to receive(:default_branch).with('https://github.com/example/repository.git').and_return('main')
      allow(git).to receive(:current_branch).and_return('modulesync')
      allow(log).to receive(:between).with('modulesync', 'origin/main').and_return(log)
      allow(log).to receive(:execute).and_return([instance_double(Git::Object::Commit)])
      expect(git).to receive(:fetch).with('origin', prune: true).ordered
      expect(git).to receive(:reset_hard).ordered
      expect(git).to receive(:pull).with('origin', 'modulesync').ordered
      expect(git_lib).to receive(:send).with(:command, 'rebase', 'origin/main').ordered

      repository.prepare_workspace(branch: 'modulesync', operate_offline: false, rebase: true)
    end
  end

  describe '#submit_changes' do
    it 'does not push an unchanged branch that was not rebased' do
      status = instance_double(Git::Status, added: {}, changed: {}, deleted: {})
      branch = instance_double(Git::Branch, checkout: true)
      allow(git).to receive(:branch).with('modulesync').and_return(branch)
      allow(git).to receive(:status).and_return(status)
      expect(git).not_to receive(:push)
      expect(git_lib).not_to receive(:send)

      result = repository.submit_changes([], branch: 'modulesync', message: 'Update', force: false)

      expect(result).to be false
    end

    it 'pushes a rebased branch even when ModuleSync made no file changes' do
      status = instance_double(Git::Status, added: {}, changed: {}, deleted: {})
      branch = instance_double(Git::Branch, checkout: true)
      repository.instance_variable_set(:@rebased, true)
      allow(git).to receive(:branch).with('modulesync').and_return(branch)
      allow(git).to receive(:status).and_return(status)
      expect(git_lib).to receive(:send)
        .with(:command, 'push', '--force-with-lease', 'origin', 'modulesync')

      result = repository.submit_changes([], branch: 'modulesync', message: 'Update', force: false)

      expect(result).to be true
    end
  end

  describe '#commit_changes' do
    it 'signs the commit when requested' do
      expect(git).to receive(:commit).with('Update', { gpg_sign: true })

      repository.commit_changes('Update', sign: true, signoff: false)
    end

    it 'uses the Git signoff option when requested' do
      expect(git_lib).to receive(:send)
        .with(:command, 'commit', '--message=Update', '--signoff')

      repository.commit_changes('Update', sign: false, signoff: true)
    end

    it 'combines amend, signing, and signoff options' do
      expect(git_lib).to receive(:send)
        .with(:command, 'commit', '--message=Update', '--amend', '--no-edit', '--gpg-sign', '--signoff')

      repository.commit_changes('Update', amend: true, sign: true, signoff: true)
    end
  end

  describe '#tag' do
    it 'signs and pushes the tag when requested' do
      expect(git).to receive(:add_tag).with('v1.2.3', sign: true)
      expect(git).to receive(:push).with('origin', 'v1.2.3')

      repository.tag('1.2.3', 'v%s', sign: true)
    end
  end
end
