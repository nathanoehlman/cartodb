# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  config.mock_with :mocha

  config.include CartoDB::Factories

  config.before(:each) do
    Rails::Sequel.connection.tables.each{ |t| next if t == :schema_migrations; Rails::Sequel.connection[t].truncate }
  end

  config.after(:each) do
    Rails::Sequel.connection[Rails::Sequel.connection.tables.first].with_sql(
      "SELECT datname FROM pg_database WHERE datistemplate IS FALSE AND datallowconn IS TRUE AND datname like 'cartodb_test_user_%'"
    ).map(:datname).each { |user_database_name| Rails::Sequel.connection.run("drop database #{user_database_name}") }
    Rails::Sequel.connection[
      "SELECT u.usename FROM pg_catalog.pg_user u"
    ].map{ |r| r.values.first }.each { |username| Rails::Sequel.connection.run("drop user #{username}") if username =~ /^cartodb_user_/ }
  end

end