require 'modulesync'
require 'modulesync/git_service'
require 'modulesync/git_service/factory'
require 'modulesync/repository'
require 'modulesync/util'

module ModuleSync
  # Provide methods to retrieve source code attributes
  class SourceCode
    attr_reader :given_name, :options

    def initialize(given_name, options)
      @options = Util.symbolize_keys(options || {})

      @given_name = given_name

      return unless given_name.include?('/')

      @repository_name = given_name.split('/').last
      @repository_namespace = given_name.split('/')[0...-1].join('/')
    end

    def repository
      @repository ||= Repository.new directory: working_directory, remote: repository_remote
    end

    def repository_name
      @repository_name ||= given_name
    end

    def repository_namespace
      @repository_namespace ||= @options[:namespace] || ModuleSync.options[:namespace]
    end

    def repository_path
      @repository_path ||= "#{repository_namespace}/#{repository_name}"
    end

    def repository_remote
      @repository_remote ||= @options[:remote] || _repository_remote
    end

    def working_directory
      @working_directory ||= File.join(ModuleSync.options[:project_root], repository_path)
    end

    def path(*parts)
      File.join(working_directory, *parts)
    end

    def git_service
      return nil if git_service_configuration.nil?

      @git_service ||= GitService::Factory.instantiate(**git_service_configuration)
    end

    def git_service_configuration
      @git_service_configuration ||= GitService.configuration_for(sourcecode: self)
    rescue GitService::UnguessableTypeError
      nil
    end

    def open_pull_request
      git_service.open_pull_request(
        repo_path: repository_path,
        namespace: repository_namespace,
        title: ModuleSync.options[:pr_title],
        message: ModuleSync.options[:message],
        source_branch: ModuleSync.options[:remote_branch] || ModuleSync.options[:branch] || repository.default_branch,
        target_branch: ModuleSync.options[:pr_target_branch] || repository.default_branch,
        labels: ModuleSync::Util.parse_list(ModuleSync.options[:pr_labels]),
        noop: ModuleSync.options[:noop],
      )
    end

    private

    def _repository_remote
      git_base = ModuleSync.options[:git_base]
      git_base.start_with?('file://') ? "#{git_base}#{repository_path}" : "#{git_base}#{repository_path}.git"
    end
  end
end
