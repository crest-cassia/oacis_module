require "rubygems"
require "bundler/setup"
require 'rspec'
Dir[File.join(File.dirname(__FILE__), "..", "app", "**/*.rb")].each{|f| require f }
