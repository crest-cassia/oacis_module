ENV['BUNDLE_GEMFILE'] = File.join(File.dirname(__FILE__), '../Gemfile')
require 'bundler/setup'
require "#{ENV["OACIS_HOME"]}/config/environment"
require 'database_cleaner'
require 'factory_girl_rails'
paths = FactoryGirl.definition_file_paths
FactoryGirl.definition_file_paths = paths.map {|path| "#{ENV["OACIS_HOME"]}/#{path}"}
FactoryGirl.find_definitions
require "#{ENV["OACIS_HOME"]}/spec/spec_helper"
Dir[File.join(File.dirname(__FILE__), "..", "lib", "**/*.rb")].each{|f| require f }

