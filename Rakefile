require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: create API doc.'
task :default => :rdoc

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


