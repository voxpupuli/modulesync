require 'find'
require 'modulesync'

module ModuleSync
  class ModuleRoot
    attr_reader :path

    def initialize(path)
      @path = path

      unless File.exist?(path)
        fail FileNotFound, "#{path} does not exist. Check that you are working in your module configs directory or that you have passed in the correct directory with -c."
      end
    end

    def source_files
      Find.find(path).collect { |file| file unless File.directory?(file) }.compact
    end
  end
end
