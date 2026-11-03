# frozen_string_literal: true

require 'English'
require 'fileutils'
require 'pathname'

require 'modulesync/cli'
require 'modulesync/constants'
require 'modulesync/hook'
require 'modulesync/puppet_module'
require 'modulesync/renderer'
require 'modulesync/settings'
require 'modulesync/util'
require 'modulesync/version'

require 'monkey_patches'

module ModuleSync
  class Error < StandardError; end

  include Constants

  def self.config_defaults
    {
      project_root: 'modules/',
      managed_modules_conf: 'managed_modules.yml',
      configs: '.',
      tag_pattern: '%s',
    }
  end

  def self.options
    @options
  end

  def self.local_file(config_path, file)
    path = File.join(config_path, MODULE_FILES_DIR, file)
    if !File.exist?("#{path}.erb") && File.exist?(path)
      warn "Warning: using '#{path}' as template without '.erb' suffix"
      path
    else
      "#{path}.erb"
    end
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
      warn "#{local_template_dir} does not exist. " \
           'Check that you are working in your module configs directory or ' \
           'that you have passed in the correct directory with -c.'
      exit 1
    end
  end

  def self.relative_names(file_list, path)
    file_list.map { |file| file.sub(/#{path}/, '') }
  end

  def self.managed_modules
    config_file = config_path(options[:managed_modules_conf], options)
    filter = options[:filter]
    negative_filter = options[:negative_filter]

    managed_modules = Util.parse_config(config_file)
    if managed_modules.empty?
      warn "No modules found in #{config_file}. " \
           'Check that you specified the right :configs directory and :managed_modules_conf file.'
      exit 1
    end
    managed_modules.select! { |m| m =~ Regexp.new(filter) } unless filter.nil?
    managed_modules.reject! { |m| m =~ Regexp.new(negative_filter) } unless negative_filter.nil?
    managed_modules.map { |given_name, options| PuppetModule.new(given_name, options) }
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

  def self.manage_file(puppet_module, filename, settings, options)
    configs = settings.build_file_configs(filename)
    target_file = puppet_module.path(filename)
    if configs['delete']
      Renderer.remove(target_file)
    else
      template_file = local_file(options[:configs], filename)
      begin
        erb = Renderer.build(template_file)
        # Meta data passed to the template as @metadata[:name]
        metadata = {
          module_name: settings.additional_settings[:puppet_module],
          namespace: settings.additional_settings[:namespace],
          workdir: puppet_module.working_directory,
          target_file: target_file,
        }
        template = Renderer.render(erb, configs, metadata)
        mode = File.stat(template_file).mode
        Renderer.sync(template, target_file, mode)
      rescue StandardError
        warn "#{puppet_module.given_name}: Error while rendering file: '#{filename}'"
        raise
      end
    end
  end

  def self.manage_module(puppet_module, module_files, defaults)
    puts "Syncing '#{puppet_module.given_name}'"
    # NOTE: #prepare_workspace now supports to execute only offline operations
    # but we totally skip the workspace preparation to keep the current behavior
    unless options[:offline]
      puppet_module.repository.prepare_workspace(branch: options[:branch],
                                                 operate_offline: false,
                                                 rebase: options[:rebase])
    end

    module_configs = Util.parse_config puppet_module.path(MODULE_CONF_FILE)
    settings = Settings.new(defaults[GLOBAL_DEFAULTS_KEY] || {},
                            defaults,
                            module_configs[GLOBAL_DEFAULTS_KEY] || {},
                            module_configs,
                            puppet_module: puppet_module.repository_name,
                            git_base: options[:git_base],
                            namespace: puppet_module.repository_namespace)

    settings.unmanaged_files(module_files).each do |filename|
      $stdout.puts "Not managing '#{filename}' in '#{puppet_module.given_name}'"
    end

    files_to_manage = settings.managed_files(module_files)
    files_to_manage.each { |filename| manage_file(puppet_module, filename, settings, options) }

    if options[:noop]
      puts "Using no-op. Files in '#{puppet_module.given_name}' may be changed but will not be committed."
      changed = puppet_module.repository.show_changes(options)
      changed && options[:pr] && puppet_module.open_pull_request
    elsif !options[:offline]
      pushed = puppet_module.repository.submit_changes(files_to_manage, options)
      # Only bump/tag if pushing didn't fail (i.e. there were changes)
      if pushed && options[:bump]
        signing_options = { sign: options[:sign], signoff: options[:signoff] }
        new = puppet_module.bump(options[:message], options[:changelog], signing_options)
        puppet_module.repository.tag(new, options[:tag_pattern], sign: options[:sign]) if options[:tag]
      end
      options[:pr] && (pushed || puppet_module.pull_request_branch_ready?) && puppet_module.open_pull_request
    end
  end

  def self.execute_in_module(puppet_module, options)
    puts "Executing in '#{puppet_module.given_name}'"
    puppet_module.repository.prepare_workspace(branch: options[:branch], operate_offline: false, rebase: options[:rebase])

    command_args = options[:command_args].dup
    env_whitelist = (options[:env] || '').split(',').map(&:strip)
    command_args[0] = File.expand_path command_args[0] if File.exist?(File.expand_path(command_args[0]))

    # Remove bundler-related env vars to allow the subprocess to run `bundle` unless explicitly whitelisted.
    command_env = ENV.reject { |k, _v| k.match?(/(^BUNDLE|^SOURCE_DATE_EPOCH$|^GEM_|RUBY)/) && !env_whitelist.include?(k) }

    success = system(command_env, *command_args, unsetenv_others: true, chdir: puppet_module.working_directory)
    unless success
      message = "Command execution failed ('#{command_args.join ' '}': #{$CHILD_STATUS})"
      raise ModuleSync::Error, message
    end

    if options[:noop]
      puts "Using no-op. Files in '#{puppet_module.given_name}' may be changed but will not be committed."
      changed = puppet_module.repository.show_changes(options)
      changed && options[:pr] && puppet_module.open_pull_request
    else
      status = puppet_module.repository.git.status
      changed_files = [status.changed, status.added, status.deleted, puppet_module.repository.untracked_unignored_files].flat_map(&:keys).uniq
      pushed = puppet_module.repository.submit_changes(changed_files, options)

      options[:pr] && (pushed || puppet_module.pull_request_branch_ready?) && puppet_module.open_pull_request
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
    @options = config_defaults.merge(cli_options)
    defaults = Util.parse_config(config_path(CONF_FILE, options))

    local_template_dir = config_path(MODULE_FILES_DIR, options)
    local_files = find_template_files(local_template_dir)
    module_files = relative_names(local_files, local_template_dir)

    # Initialize every Git service before updating any repository.
    # This validates PR credentials before an update can commit or push changes.
    initialized_modules = managed_modules
    initialized_modules.each(&:git_service) if options[:pr]

    errors = false
    initialized_modules.each do |puppet_module|
      manage_module(puppet_module, module_files, defaults)
    rescue ModuleSync::Error, Git::Error => e
      message = e.message || 'Error during `update`'
      warn "#{puppet_module.given_name}: #{message}"
      exit 1 unless options[:skip_broken]
      errors = true
      $stdout.puts "Skipping '#{puppet_module.given_name}' as update process failed"
    rescue StandardError
      raise unless options[:skip_broken]

      errors = true
      $stdout.puts "Skipping '#{puppet_module.given_name}' as update process failed"
    end
    exit 1 if errors && options[:fail_on_warnings]
  end

  def self.clone(cli_options)
    @options = config_defaults.merge(cli_options)

    managed_modules.each do |puppet_module|
      puppet_module.repository.clone unless puppet_module.repository.cloned?
    end
  end

  def self.execute(cli_options)
    @options = config_defaults.merge(cli_options)

    initialized_modules = managed_modules
    initialized_modules.each(&:git_service) if options[:pr]

    errors = false
    initialized_modules.each do |puppet_module|
      execute_in_module(puppet_module, options)
    rescue ModuleSync::Error, Git::Error => e
      message = e.message || 'Error during `execute`'
      warn "#{puppet_module.given_name}: #{message}"
      exit 1 unless options[:skip_broken]
      errors = true
      warn "Skipping '#{puppet_module.given_name}' as execute process failed"
    rescue StandardError
      raise unless options[:skip_broken]

      errors = true
      warn "Skipping '#{puppet_module.given_name}' as execute process failed"
    end
    exit 1 if errors
  end

  def self.reset(cli_options)
    @options = config_defaults.merge(cli_options)
    if @options[:branch].nil?
      raise Thor::Error,
            "Error: 'branch' option is missing, please set it in configuration or in command line."
    end

    managed_modules.each do |puppet_module|
      puppet_module.repository.reset_workspace(
        branch: @options[:branch],
        source_branch: @options[:source_branch],
        operate_offline: @options[:offline],
      )
    end
  end

  def self.push(cli_options)
    @options = config_defaults.merge(cli_options)

    if @options[:branch].nil?
      raise Thor::Error,
            "Error: 'branch' option is missing, please set it in configuration or in command line."
    end

    managed_modules.each do |puppet_module|
      puppet_module.repository.push branch: @options[:branch], remote_branch: @options[:remote_branch]
    rescue ModuleSync::Error => e
      raise Thor::Error, "#{puppet_module.given_name}: #{e.message}"
    end
  end
end
