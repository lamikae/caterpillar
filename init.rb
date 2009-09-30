#--
# (c) Copyright 2008,2009 Mikael Lammentausta
#
# See the file MIT-LICENSE included with the distribution for
# software license details.
#++

### Initialize the Rails plugin.

file = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
this_dir = File.dirname(File.expand_path(file))

# load the main file
require File.join(this_dir, 'lib', 'caterpillar')

#STDERR.puts 'Caterpillar: version %s' % Caterpillar::VERSION

# Add Caterpillar portlet navigation to views paths
ActionController::Base.append_view_path File.join(this_dir, 'views')

### Initialize the portlet test bench

# Adding directories to the load path makes them appear just like files in the the main app directory.
%w{ controllers helpers }.each do |path|
  ActiveSupport::Dependencies.load_paths << File.join(this_dir, 'portlet_test_bench', path)
end

# Removing a directory from the load once paths allow changes
# to be picked up as soon as you save the file – without having to restart the web server.
ActiveSupport::Dependencies.load_once_paths.delete(File.join(this_dir, 'portlet_test_bench'))

# Add views
ActionController::Base.append_view_path File.join(this_dir, 'portlet_test_bench','views')

# Define routes
# NOTE: the routes need to be activated by 'map.caterpillar' in RAILS_ROOT/config/routes.rb
require File.join(this_dir, 'portlet_test_bench', 'routing')
ActionController::Routing::RouteSet::Mapper.send :include, Caterpillar::Routing::MapperExtensions

# hack; the application controller needs to be loaded explicitly,
# but NOT for standard Caterpillar tasks (breaks the tasks)
unless $0[/caterpillar|generate/]
  require File.join(this_dir, 'portlet_test_bench','controllers','caterpillar','application')
end
