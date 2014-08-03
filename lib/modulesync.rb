require 'fileutils'
require 'modulesync/cli'
require 'modulesync/constants'
require 'modulesync/git'
require 'modulesync/renderer'
require 'modulesync/version'

module ModuleSync
  include Constants

  def self.local_file(file)
    "#{MODULE_FILES_DIR}/#{file}"
  end

   def self.module_file(puppet_module, file)
    "#{PROJ_ROOT}/#{puppet_module}/#{file}"
  end

  def self.local_files
    module_files_dir = File.expand_path('..', MODULE_FILES_DIR)
    local_files = Find.find(MODULE_FILES_DIR).collect { |file| file if !File.directory?(file) }.compact
  end

  def self.run(args)
    cli = CLI.new
    cli.parse_opts(args)
    options  = cli.options
    defaults = Renderer.parse_config(CONF_FILE)

    local_files = self.local_files
    module_files = local_files.map { |file| file.sub(/#{MODULE_FILES_DIR}/, '') }

    managed_modules = Renderer.parse_config(options[:managed_modules_conf])
    if managed_modules.empty?
      puts "No modules found. Check that you specified the write config file."
      exit
    end

    managed_modules.each do |puppet_module|
      puts "Syncing #{puppet_module}"
      puts options[:namespace]
      Git.pull(options[:namespace], puppet_module)
      module_configs = Renderer.parse_config("#{PROJ_ROOT}/#{puppet_module}/#{MODULE_CONF_FILE}")
      files_to_manage = module_files | defaults.keys | module_configs.keys
      files_to_delete = []
      files_to_manage.each do |file|
        file_configs = (defaults[file] || {}).merge(module_configs[file] || {})
        if file_configs['unmanaged']
          puts "Not managing #{file} in #{puppet_module}"
          files_to_delete << file
        elsif file_configs['delete']
          Renderer.remove(module_file(puppet_module, file))
        else
          erb = Renderer.build(Util.local_file(file))
          template = Renderer.render(erb, file_configs)
          Renderer.sync(template, "#{PROJ_ROOT}/#{puppet_module}/#{file}")
        end
      end
      files_to_manage -= files_to_delete
      if options[:noop]
        puts "Using no-op. Files in #{puppet_module} may be changed but will not be committed."
        Git.update_noop(puppet_module, options[:branch])
        puts "\n\n"
        puts '--------------------------------'
      else
        Git.update(puppet_module, files_to_manage, options[:message], options[:branch])
      end
    end
  end

end
