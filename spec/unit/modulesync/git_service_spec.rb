require 'modulesync/git_service'

describe ModuleSync::GitService do
  context 'when instantiate a GitHub service without credentials' do
    it 'raises an error' do
      expect { ModuleSync::GitService.instantiate(type: :github, options: nil) }.to raise_error(ModuleSync::Error, 'No GitHub token specified to create a pull request')
    end
  end

  context 'when instantiate a GitLab service without credentials' do
    it 'raises an error' do
      expect { ModuleSync::GitService.instantiate(type: :gitlab, options: nil) }.to raise_error(ModuleSync::Error, 'No GitLab token specified to create a merge request')
    end
  end
end
