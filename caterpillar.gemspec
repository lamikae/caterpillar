require 'rubygems'
require 'rake'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'lib/caterpillar'

Gem::Specification.new do |s|
  s.name = %q{caterpillar}
  s.authors = ["Mikael Lammentausta"]
  s.email = %q{mikael.lammentausta@gmail.com}
  s.homepage = %q{http://rails-portlet.rubyforge.org}
  s.version = Caterpillar::VERSION

# lportal has broken system of requiring Rails gems....
#  s.add_dependency("lportal", ">= 1.0.18")
  if RUBY_PLATFORM =~ /java/
	# FIXME: Just make sure the hpricot-java gem is installed...
#	 s.add_dependency("hpricot", ">= 0.6.164", 'java')
  else
	 s.add_dependency("hpricot", ">= 0.6.164")
  end

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.description = %q{= Caterpillar}
  s.platform = Gem::Platform::RUBY

  s.executables = ["caterpillar"]
  s.default_executable = %q{caterpillar}

  s.files = FileList["Rakefile", "*.rb", "lib/**/*", "generators/**/*", "db/**/*", "views/**/*",
    "portlet_test_bench/**/*"].to_a

  s.has_rdoc = true
  s.extra_rdoc_files = ["README.rdoc","MIT-LICENSE","ChangeLog"]
  s.rdoc_options = ["--main", "README.rdoc"]
  s.rdoc_options << '--line-numbers' << '--inline-source'
  s.rubyforge_project = %q{rails-portlet}
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{Caterpillar helps building Rails applications for JSR286 portlets.}
  s.test_files = FileList["{test}/**/*test.rb"].to_a

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_runtime_dependency(%q<rake>, [">= 0.7.3"])
    else
      s.add_dependency(%q<rake>, [">= 0.7.3"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0.7.3"])
  end
end
