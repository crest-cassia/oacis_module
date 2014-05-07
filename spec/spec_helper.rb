ENV['BUNDLE_GEMFILE'] = File.join(File.dirname(__FILE__), '../Gemfile')
require 'bundler/setup'
ENV["RAILS_ENV"] = 'test'
require "#{ENV["OACIS_HOME"]}/config/environment"
require "#{ENV["OACIS_HOME"]}/spec/spec_helper"
Dir[File.join(File.dirname(__FILE__), "..", "lib", "**/*.rb")].each{|f| require f }

