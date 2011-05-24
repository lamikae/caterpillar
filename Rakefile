require 'rake'
require 'rake/testtask'
require 'spec/rake/spectask'
require 'spec/rake/verify_rcov'

desc 'Default: create API doc.'
task :default => :rdoc

desc "Create the caterpillar gem file"
task :gem do
  spec = eval(IO.read("caterpillar.gemspec"))
  Gem::Builder.new(spec).build
end

Spec::Rake::SpecTask.new do |t|
  t.spec_opts ||= []
  t.spec_opts << "--options" << "spec/spec.opts"
end

Spec::Rake::SpecTask.new("spec:rcov") do |t|
  t.spec_opts ||= []
  t.spec_opts << "--options" << "spec/spec.opts"
  t.rcov = true
  t.rcov_opts = ['--exclude', 'diff-lcs,rake,spec,rcov,active_support,action_controller,action_view,json,rack']
end
