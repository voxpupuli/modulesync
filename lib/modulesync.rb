require 'fileutils'
require 'modulesync/cli'
require 'modulesync/constants'
require 'modulesync/git'
require 'modulesync/hook'
require 'modulesync/renderer'
require 'modulesync/util'

module ModuleSync
  include Constants

  def self.config_defaults
    {
      :project_root         => 'modules/',
      :git_base             => 'git@github.com:',
      :managed_modules_conf => 'managed_modules.yml',
      :configs              => '.',
      :tag_pattern          => '%s',
    }
  end

  def self.local_file(config_path, file)
    "#{config_path}/#{MODULE_FILES_DIR}/#{file}"
  end

  def self.module_file(project_root, puppet_module, file)
    "#{project_root}/#{puppet_module}/#{file}"
  end

  def self.local_files(path)
    if File.exist?(path)
      local_files = Find.find(path).collect { |file| file unless File.directory?(file) }.compact
    else
      puts "#{path} does not exist. Check that you are working in your module configs directory or that you have passed in the correct directory with -c."
      exit
    end
  end

  def self.module_files(local_files, path)
    local_files.map { |file| file.sub(/#{path}/, '') }
  end

  def self.managed_modules(path, filter)
    managed_modules = Util.parse_config(path)
    if managed_modules.empty?
      puts "No modules found at #{path}. Check that you specified the right configs directory containing managed_modules.yml."
      exit
    end
    managed_modules.select! { |m| m =~ Regexp.new(filter) } unless filter.nil?
    managed_modules
  end

  def self.module_name(module_name, default_namespace)
    if module_name.include?('/')
      namespace, module_name = module_name.split('/')
    else
      return [default_namespace, module_name]
    end
  end

  def self.run(options)
    options = config_defaults.merge(options)

    if options[:command] == 'update'
      defaults = Util.parse_config("#{options[:configs]}/#{CONF_FILE}")

      path = "#{options[:configs]}/#{MODULE_FILES_DIR}"
      local_files = self.local_files(path)
      module_files = self.module_files(local_files, path)

      managed_modules = self.managed_modules("#{options[:configs]}/managed_modules.yml", options[:filter])

      # managed_modules is either an array or a hash
      managed_modules.each do |puppet_module, opts|
        puts "Syncing #{puppet_module}"
        namespace, module_name = self.module_name(puppet_module, options[:namespace])
        unless options[:offline]
          git_base = "#{options[:git_base]}#{namespace}"
          Git.pull(git_base, module_name, options[:branch], options[:project_root], opts || {})
        end
        module_configs = Util.parse_config("#{options[:project_root]}/#{module_name}/#{MODULE_CONF_FILE}")
        global_defaults = defaults[GLOBAL_DEFAULTS_KEY] || {}
        module_defaults = module_configs[GLOBAL_DEFAULTS_KEY] || {}
        files_to_manage = (module_files | defaults.keys | module_configs.keys) - [GLOBAL_DEFAULTS_KEY]
        files_to_delete = []
        files_to_manage.each do |file|
          file_configs = global_defaults.merge(defaults[file] || {}).merge(module_defaults).merge(module_configs[file] || {})
          file_configs[:puppet_module] = module_name
          if file_configs['unmanaged']
            puts "Not managing #{file} in #{module_name}"
            files_to_delete << file
          elsif file_configs['delete']
            Renderer.remove(module_file(options['project_root'], module_name, file))
          else
            erb = Renderer.build(local_file(options[:configs], file))
            template = Renderer.render(erb, file_configs)
            Renderer.sync(template, "#{options[:project_root]}/#{module_name}/#{file}")
          end
        end
        files_to_manage -= files_to_delete
        if options[:noop]
          Git.update_noop(module_name, options)
        elsif !options[:offline]
          Git.update(module_name, files_to_manage, options)
        end
      end
    elsif options[:command] == 'hook'
      Hook.hook(options[:hook], options)
    end
  end
end
