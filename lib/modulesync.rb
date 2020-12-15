require 'fileutils'
require 'pathname'
require 'modulesync/cli'
require 'modulesync/constants'
require 'modulesync/git'
require 'modulesync/hook'
require 'modulesync/renderer'
require 'modulesync/settings'
require 'modulesync/util'
require 'monkey_patches'

module ModuleSync # rubocop:disable Metrics/ModuleLength
  class Error < StandardError; end

  include Constants

  def self.config_defaults
    {
      :project_root         => 'modules/',
      :managed_modules_conf => 'managed_modules.yml',
      :configs              => '.',
      :tag_pattern          => '%s'
    }
  end

  def self.local_file(config_path, file)
    File.join(config_path, MODULE_FILES_DIR, file)
  end

  def self.module_file(project_root, namespace, puppet_module, *parts)
    File.join(project_root, namespace, puppet_module, *parts)
  end

  # List all template files.
  #
  # Only select *.erb files, and strip the extension. This way all the code will only have to handle bare paths,
  # except when reading the actual ERB text
  def self.find_template_files(local_template_dir)
    if File.exist?(local_template_dir)
      Find.find(local_template_dir).find_all { |p| p =~ /.erb$/ && !File.directory?(p) }
          .collect { |p| p.chomp('.erb') }
          .to_a
    else
      $stdout.puts "#{local_template_dir} does not exist." \
        ' Check that you are working in your module configs directory or' \
        ' that you have passed in the correct directory with -c.'
      exit
    end
  end

  def self.relative_names(file_list, path)
    file_list.map { |file| file.sub(/#{path}/, '') }
  end

  def self.managed_modules(config_file, filter, negative_filter)
    managed_modules = Util.parse_config(config_file)
    if managed_modules.empty?
      $stdout.puts "No modules found in #{config_file}." \
        ' Check that you specified the right :configs directory and :managed_modules_conf file.'
      exit
    end
    managed_modules.select! { |m| m =~ Regexp.new(filter) } unless filter.nil?
    managed_modules.reject! { |m| m =~ Regexp.new(negative_filter) } unless negative_filter.nil?
    managed_modules
  end

  def self.module_name(module_name, default_namespace)
    return [default_namespace, module_name] unless module_name.include?('/')
    ns, mod = module_name.split('/')
  end

  def self.hook(options)
    hook = Hook.new(HOOK_FILE, options)

    case options[:hook]
    when 'activate'
      hook.activate
    when 'deactivate'
      hook.deactivate
    end
  end

  def self.manage_file(filename, settings, options)
    namespace = settings.additional_settings[:namespace]
    module_name = settings.additional_settings[:puppet_module]
    configs = settings.build_file_configs(filename)
    target_file = module_file(options[:project_root], namespace, module_name, filename)
    if configs['delete']
      Renderer.remove(target_file)
    else
      templatename = local_file(options[:configs], filename)
      begin
        erb = Renderer.build(templatename)
        # Meta data passed to the template as @metadata[:name]
        metadata = {
          :module_name => module_name,
          :workdir     => module_file(options[:project_root], namespace, module_name),
          :target_file => target_file,
        }
        template = Renderer.render(erb, configs, metadata)
        Renderer.sync(template, target_file)
      rescue # rubocop:disable Lint/RescueWithoutErrorClass
        $stderr.puts "Error while rendering #{filename}"
        raise
      end
    end
  end

  def self.manage_module(puppet_module, module_files, module_options, defaults, options)
    default_namespace = options[:namespace]
    if module_options.is_a?(Hash) && module_options.key?(:namespace)
      default_namespace = module_options[:namespace]
    end
    namespace, module_name = module_name(puppet_module, default_namespace)
    git_repo = File.join(namespace, module_name)
    unless options[:offline]
      Git.pull(options[:git_base], git_repo, options[:branch], options[:project_root], module_options || {})
    end

    module_configs = Util.parse_config(module_file(options[:project_root], namespace, module_name, MODULE_CONF_FILE))
    settings = Settings.new(defaults[GLOBAL_DEFAULTS_KEY] || {},
                            defaults,
                            module_configs[GLOBAL_DEFAULTS_KEY] || {},
                            module_configs,
                            :puppet_module => module_name,
                            :git_base => options[:git_base],
                            :namespace => namespace)
    settings.unmanaged_files(module_files).each do |filename|
      $stdout.puts "Not managing #{filename} in #{module_name}"
    end

    files_to_manage = settings.managed_files(module_files)
    files_to_manage.each { |filename| manage_file(filename, settings, options) }

    if options[:noop]
      Git.update_noop(git_repo, options)
      options[:pr] && pr(module_options).manage(namespace, module_name, options)
    elsif !options[:offline]
      pushed = Git.update(git_repo, files_to_manage, options)
      pushed && options[:pr] && pr(module_options).manage(namespace, module_name, options)
    end
  end

  def self.config_path(file, options)
    return file if Pathname.new(file).absolute?
    File.join(options[:configs], file)
  end

  def config_path(file, options)
    self.class.config_path(file, options)
  end

  def self.update(cli_options)
    prepare = lambda { |options|
      local_template_dir = config_path(MODULE_FILES_DIR, options)
      local_files = find_template_files(local_template_dir)
      module_files = relative_names(local_files, local_template_dir)
      return options.merge(_module_files: module_files)
    }

    job = lambda { |puppet_module, module_options, defaults, options|
      manage_module(puppet_module, options[:_module_files], module_options, defaults, options)
    }

    run(cli_options, job, prepare)
  end

  def self.push(cli_options)
    job = lambda { |puppet_module, module_options, _defaults, options|
      default_namespace = module_options[:namespace] || options[:namespace]
      namespace, module_name = module_name(puppet_module, default_namespace)
      repo_dir = File.join(options[:project_root], namespace, module_name)

      begin
        repo = ::Git.open repo_dir
      rescue ArgumentError => e
        raise unless e.message == 'path does not exist'
        raise ModuleSync::Error, 'Repository must be locally available before trying to push'
      end
      Git.push(repo, options)
      options[:pr] && pr(module_options).manage(namespace, module_name, options)
    }

    run(cli_options, job)
  end

  def self.run(options, job, prepare = nil)
    options = config_defaults.merge(options)
    options[:remote_branch] ||= options[:branch]
    defaults = Util.parse_config(config_path(CONF_FILE, options))
    if options[:pr]
      unless options[:branch]
        $stderr.puts 'A branch must be specified with --branch to use --pr!'
        raise
      end

      @pr = create_pr_manager if options[:pr]
    end

    options = prepare.call(options) unless prepare.nil?

    managed_modules = self.managed_modules(config_path(options[:managed_modules_conf], options),
                                           options[:filter],
                                           options[:negative_filter])

    errors = false
    # managed_modules is either an array or a hash
    managed_modules.each do |puppet_module, module_options|
      module_options ||= {}
      module_options = Util.symbolize_keys(module_options)
      begin
        job.call(puppet_module, module_options, defaults, options)
      rescue StandardError => e
        message = e.message || "Error during '#{options[:command]}'"
        message = "#{puppet_module}: #{message}"
        $stderr.puts message
        raise unless options[:skip_broken]
        errors = true
        $stdout.puts "Skipping #{puppet_module} as '#{options[:command]}' process failed"
      end
    end
    exit 1 if errors && options[:fail_on_warnings]
  end

  def self.pr(module_options)
    module_options ||= {}
    github_conf = module_options[:github]
    gitlab_conf = module_options[:gitlab]

    if !github_conf.nil?
      base_url = github_conf[:base_url] || ENV.fetch('GITHUB_BASE_URL', 'https://api.github.com')
      require 'modulesync/pr/github'
      ModuleSync::PR::GitHub.new(github_conf[:token], base_url)
    elsif !gitlab_conf.nil?
      base_url = gitlab_conf[:base_url] || ENV.fetch('GITLAB_BASE_URL', 'https://gitlab.com/api/v4')
      require 'modulesync/pr/gitlab'
      ModuleSync::PR::GitLab.new(gitlab_conf[:token], base_url)
    elsif @pr.nil?
      $stderr.puts 'No GitHub or GitLab token specified for --pr!'
      raise
    else
      @pr
    end
  end

  def self.create_pr_manager
    github_token = ENV.fetch('GITHUB_TOKEN', '')
    gitlab_token = ENV.fetch('GITLAB_TOKEN', '')

    if !github_token.empty?
      require 'modulesync/pr/github'
      ModuleSync::PR::GitHub.new(github_token, ENV.fetch('GITHUB_BASE_URL', 'https://api.github.com'))
    elsif !gitlab_token.empty?
      require 'modulesync/pr/gitlab'
      ModuleSync::PR::GitLab.new(gitlab_token, ENV.fetch('GITLAB_BASE_URL', 'https://gitlab.com/api/v4'))
    else
      warn '--pr specified without environment variables GITHUB_TOKEN or GITLAB_TOKEN'
    end
  end
end
