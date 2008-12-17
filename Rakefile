require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: create API doc.'
task :default => :rdoc

desc 'Test the example plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the example plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Caterpillar'
  rdoc.main = 'README'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.rdoc_files.include('generators/**/*.rb')
  rdoc.options << '--line-numbers' << '--inline-source' << '-U'
end


