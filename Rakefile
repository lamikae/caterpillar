require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'
load 'caterpillar.gemspec'

# gem install rspec -v 1.3.0
require 'spec/rake/spectask'
# gem install rcov
require 'spec/rake/verify_rcov'

desc 'Default: create API doc.'
task :default => :rdoc

Spec::Rake::SpecTask.new do |t|
  t.spec_opts ||= []
  t.spec_opts << "--options" << "spec/spec.opts"
end

Spec::Rake::SpecTask.new("spec:rcov") do |t|
  t.spec_opts ||= []
  t.spec_opts << "--options" << "spec/spec.opts"
  t.rcov = true
#  t.rcov_opts = ['--text-report', '--exclude', "gems/,spec/,rcov.rb,#{File.expand_path(File.join(File.dirname(__FILE__),'../../..'))}"] 
  t.rcov_opts = ['--exclude', 'diff-lcs,rake,spec,rcov,active_support,action_controller,action_view,json,rack']
end

RCov::VerifyTask.new(:rcov => "spec:rcov") do |t|
  t.threshold = 100
end

desc 'Generate documentation for the example plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Caterpillar'
  rdoc.main = 'README.rdoc'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.rdoc_files.include('generators/**/*.rb')
  rdoc.options << '--line-numbers' << '--inline-source' << '-U'
end
