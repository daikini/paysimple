require 'rubygems'
require 'hoe'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require './lib/paysimple.rb'

Hoe.new('paysimple', PaySimple::VERSION) do |p|
  p.rubyforge_name = 'paysimple'
  p.author = ["Jonathan Younger"]
  p.email = ["jonathan@daikini.com"]
  p.summary = "Ruby library for the PaySimple payment gateway."
  p.description = p.paragraphs_of('README.txt', 2..5).join("\n\n")
  p.url = "http://paysimple.rubyforge.org/"
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
  p.remote_rdoc_dir = "" # Release to root
  p.extra_deps << ["soap4r", ">= 1.5.6"]
end

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the paysimple plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the paysimple plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'PaySimple'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
