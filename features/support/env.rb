require 'aruba/cucumber'

require_relative '../../spec/helpers/faker'

Faker.working_directory = File.expand_path("#{Aruba.config.working_directory}/faker")

Before do
  @aruba_timeout_seconds = 5
end
