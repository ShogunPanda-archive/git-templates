ENV["RAILS_ENV"] ||= "test"

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start("rails")
end

# Rails environment
require File.expand_path("../../config/environment", __FILE__)

# RSpec related
require "rspec/rails"

# Support files
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# Rspec configuration
RSpec.configure do |config|
  config.add_formatter RSpec::Core::Formatters::ProgressFormatter if config.formatter_loader.formatters.empty?
  config.infer_base_class_for_anonymous_controllers = false
  config.order = "random"
  config.use_transactional_fixtures = false
  config.tty = true
  config.color = ENV["NO_COLOR"].nil?
  config.include FactoryGirl::Syntax::Methods

  config.before(:suite) do
    # Change the timezone
    ENV["ORIGINAL_TZ"] = ENV["TZ"]
    ENV["TZ"] = "UTC"

    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
    Timecop.freeze(DateTime.civil(2016, 5, 4, 3, 2, 1, 0))
    FactoryGirl.find_definitions
  end

  config.after(:suite) do
    ENV["TZ"] = ENV.delete("ORIGINAL_TZ")
    Timecop.return
  end
end