require 'erb'
require 'find'

module ModuleSync
  module Renderer
    class ForgeModuleFile
      def initialize(configs = {})
        @configs = configs
      end
    end

    def self.build(from_erb_template)
      from_erb_template = from_erb_template.chomp('.erb')
      template_file = if File.exist?("#{from_erb_template}.erb")
                        "#{from_erb_template}.erb"
                      else
                        from_erb_template
                      end
      erb_obj = ERB.new(File.read(template_file), nil, '-')
      erb_obj.filename = from_erb_template
      erb_obj.def_method(ForgeModuleFile, 'render()', template_file)
      erb_obj
    end

    def self.remove(file)
      File.delete(file) if File.exist?(file)
    end

    def self.render(_template, configs = {})
      ForgeModuleFile.new(configs).render
    end

    def self.sync(template, to_file)
      path = to_file.rpartition('/').first
      FileUtils.mkdir_p(path) unless path.empty?
      File.open(to_file.chomp('.erb'), 'w') do |file|
        file.write(template)
      end
    end
  end
end
