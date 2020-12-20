# Faker is a top-level module to keep global faker config
module Faker
  def self.working_directory=(path)
    @working_directory = path
  end

  def self.working_directory
    raise 'Working directory must be set' if @working_directory.nil?
    FileUtils.mkdir_p @working_directory
    @working_directory
  end
end
