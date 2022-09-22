require 'erb'
require 'find'

module ModuleSync
  module Renderer
    class ForgeModuleFile
      def initialize(configs = {}, metadata = {})
        @configs = configs
        @metadata = metadata
      end
    end

    def self.build(target_name)
      template_file = if !File.exist?("#{target_name}.erb") && File.exist?(target_name)
                        $stderr.puts "Warning: using '#{target_name}' as template without '.erb' suffix"
                        target_name
                      else
                        "#{target_name}.erb"
                      end
      template = File.read(template_file)
      erb_obj = if RUBY_VERSION >= '2.7'
                  ERB.new(template, trim_mode: '-')
                else
                  ERB.new(template, nil, '-')
                end
      erb_obj.filename = template_file
      erb_obj.def_method(ForgeModuleFile, 'render()', template_file)
      erb_obj
    end

    def self.remove(file)
      FileUtils.rm_f(file)
    end

    def self.render(_template, configs = {}, metadata = {})
      ForgeModuleFile.new(configs, metadata).render
    end

    def self.sync(template, target_name)
      FileUtils.mkdir_p(File.dirname(target_name))
      File.write(target_name, template)
    end
  end
end
