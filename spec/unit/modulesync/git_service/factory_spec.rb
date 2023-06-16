require 'modulesync'
require 'modulesync/git_service/factory'

describe ModuleSync::GitService::Factory do
  context 'when instantiate a GitHub service without credentials' do
    it 'raises an error' do
      expect do
        ModuleSync::GitService::Factory.instantiate(type: :github, endpoint: nil,
                                                    token: nil)
      end.to raise_error(ModuleSync::GitService::MissingCredentialsError)
    end
  end

  context 'when instantiate a GitLab service without credentials' do
    it 'raises an error' do
      expect do
        ModuleSync::GitService::Factory.instantiate(type: :gitlab, endpoint: nil,
                                                    token: nil)
      end.to raise_error(ModuleSync::GitService::MissingCredentialsError)
    end
  end
end
