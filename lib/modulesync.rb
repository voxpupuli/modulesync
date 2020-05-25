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

GITHUB_TOKEN = ENV.fetch('GITHUB_TOKEN', '')
GITLAB_TOKEN = ENV.fetch('GITLAB_TOKEN', '')

module ModuleSync # rubocop:disable Metrics/ModuleLength
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
    namespace, module_name = module_name(puppet_module, options[:namespace])
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
    elsif !options[:offline]
      pushed = Git.update(git_repo, files_to_manage, options)
      pushed && options[:pr] && @pr.manage(namespace, module_name, options)
    end
  end

  def self.update(options)
    options = config_defaults.merge(options)
    defaults = Util.parse_config(File.join(options[:configs], CONF_FILE))
    if options[:pr]
      unless options[:branch]
        $stderr.puts 'A branch must be specified with --branch to use --pr!'
        raise
      end

      @pr = create_pr_manager if options[:pr]
    end

    local_template_dir = File.join(options[:configs], MODULE_FILES_DIR)
    local_files = find_template_files(local_template_dir)
    module_files = relative_names(local_files, local_template_dir)

    managed_modules = self.managed_modules(File.join(options[:configs], options[:managed_modules_conf]),
                                           options[:filter],
                                           options[:negative_filter])

    errors = false
    # managed_modules is either an array or a hash
    managed_modules.each do |puppet_module, module_options|
      begin
        manage_module(puppet_module, module_files, module_options, defaults, options)
      rescue # rubocop:disable Lint/RescueWithoutErrorClass
        $stderr.puts "Error while updating #{puppet_module}"
        raise unless options[:skip_broken]
        errors = true
        $stdout.puts "Skipping #{puppet_module} as update process failed"
      end
    end
    exit 1 if errors && options[:fail_on_warnings]
  end

  def self.create_pr_manager
    if !GITHUB_TOKEN.empty?
      require 'modulesync/pr/github'
      ModuleSync::PR::GitHub.new(GITHUB_TOKEN, ENV.fetch('GITHUB_BASE_URL', 'https://api.github.com'))
    elsif !GITLAB_TOKEN.empty?
      require 'modulesync/pr/github'
      ModuleSync::PR::GitLab.new(GITLAB_TOKEN, ENV.fetch('GITLAB_BASE_URL', 'https://gitlab.com/api/v4'))
    else
      $stderr.puts 'Environment variables GITHUB_TOKEN or GITLAB_TOKEN must be set to use --pr!'
      raise
    end
  end
end
