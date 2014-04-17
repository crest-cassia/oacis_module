# load oacis Gemfile
require 'pathname'
oacis_gemfile = Pathname("#{ENV["OACIS_HOME"]}/Gemfile")
puts "Loading #{file} ..." if $DEBUG # `ruby -d` or `bundle -v`
instance_eval File.read(oacis_gemfile)

# Load module's Gemfiles
Dir.glob File.expand_path("plugins/*/Gemfile", __FILE__) do |file|
  puts "Loading #{file} ..." if $DEBUG # `ruby -d` or `bundle -v`
  instance_eval File.read(file)
end

# define oacid-module gems
source 'https://rubygems.org'

# utility tool
gem 'rspec'
gem 'pry'

