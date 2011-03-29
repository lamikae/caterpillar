require 'rubygems'
require 'rake'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'lib/caterpillar'

Gem::Specification.new do |s|
  s.name = %q{caterpillar}
  s.authors = ["Mikael Lammentausta"]
  s.email = %q{mikael.lammentausta@gmail.com}
  s.homepage = %q{http://github.com/lamikae/caterpillar}
  s.version = Caterpillar::VERSION
    
	s.add_dependency("hpricot", ">= 0.6.164")
	s.add_dependency("jrexml")
	s.add_dependency("rake")

  s.description = %q{= Caterpillar}

  s.executables = ["caterpillar"]
  s.default_executable = %q{caterpillar}

  s.files = `git ls-files`.split("\n")

  s.extra_rdoc_files = ["README.rdoc","MIT-LICENSE","ChangeLog"]
  s.rdoc_options = ["--main", "README.rdoc"]
  s.rdoc_options << '--line-numbers' << '--inline-source'
  s.rubyforge_project = %q{rails-portlet}
  s.summary = %q{Caterpillar helps building Rails applications for JSR286 portlets.}
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
end
