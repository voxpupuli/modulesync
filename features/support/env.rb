# frozen_string_literal: true

require 'aruba/cucumber'

require_relative '../../spec/helpers/faker'

Before do
  @aruba_timeout_seconds = 5

  aruba.config.activate_announcer_on_command_failure = %i[stdout stderr]
  ModuleSync::Faker.working_directory = File.expand_path('faker', aruba.home_directory)
end
