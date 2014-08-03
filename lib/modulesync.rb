require 'fileutils'
require 'modulesync/cli'
require 'modulesync/constants'
require 'modulesync/git'
require 'modulesync/renderer'

module ModuleSync
  include Constants

  def self.local_file(config_path, file)
    "#{config_path}/#{MODULE_FILES_DIR}/#{file}"
  end

   def self.module_file(puppet_module, file)
    "#{PROJ_ROOT}/#{puppet_module}/#{file}"
  end

  def self.local_files(path)
    if File.exists?(path)
      local_files = Find.find(path).collect { |file| file if !File.directory?(file) }.compact
    else
      puts "No #{MODULE_FILES_DIR} directory exists. Check that you are working
in your module configs directory or that you have passed in the
correct directory with -c."
      exit
    end
  end

  def self.module_files(local_files, path)
    local_files.map { |file| file.sub(/#{path}/, '') }
  end

  def self.managed_modules(path)
    managed_modules = Renderer.parse_config(path)
    if managed_modules.empty?
      puts "No modules found. Check that you specified the write configs directory containing managed_modules.yml."
      exit
    end
    managed_modules
  end

  def self.run(args)
    cli = CLI.new
    cli.parse_opts(args)
    options  = cli.options
    if options[:command] == 'update'
      defaults = Renderer.parse_config("#{options[:configs]}/#{CONF_FILE}")

      path = "#{options[:configs]}/#{MODULE_FILES_DIR}"
      local_files = self.local_files(path)
      module_files = self.module_files(local_files, path)

      managed_modules = self.managed_modules("#{options[:configs]}/managed_modules.yml")

      managed_modules.each do |puppet_module|
        puts "Syncing #{puppet_module}"
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
            erb = Renderer.build(local_file(options[:configs], file))
            template = Renderer.render(erb, file_configs)
            Renderer.sync(template, "#{PROJ_ROOT}/#{puppet_module}/#{file}")
          end
        end
        files_to_manage -= files_to_delete
        if options[:noop]
          Git.update_noop(puppet_module, options[:branch])
        else
          Git.update(puppet_module, files_to_manage, options[:message], options[:branch])
        end
      end
    else
      
    end
  end

end
