# encoding: utf-8
#--
# (c) Copyright 2008 - 2011 Mikael Lammentausta
#               2010 - 2011 Tulio Ornelas dos Santos
#
# See the file MIT-LICENSE included with the distribution for
# software license details.
#++

### Initializes the Rails2 plugin

file = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
this_dir = File.dirname(File.expand_path(file))

# load the main file
require File.join(this_dir, 'lib', 'caterpillar')

# Add Caterpillar portlet navigation to views paths
ActionController::Base.append_view_path File.join(this_dir, 'views')

# Detect Rails version to use proper load commands
v = RailsGemChooser.version
raise 'Unable to detect available Rails version' unless v
rails_version = v.gsub('.','').to_i

### Initialize the portlet test bench

# Adding directories to the load path makes them appear just like files in the the main app directory.
%w{ controllers helpers }.each do |path|
  if rails_version > 238
    # this changed between 2.3.8 and 2.3.10
    ActiveSupport::Dependencies.autoload_paths << File.join(this_dir, 'portlet_test_bench', path)
  else
    ActiveSupport::Dependencies.load_paths << File.join(this_dir, 'portlet_test_bench', path)
  end
end

# Removing a directory from the load once paths allow changes
# to be picked up as soon as you save the file – without having to restart the web server.
if rails_version > 238
  # this changed between 2.3.8 and 2.3.10
  ActiveSupport::Dependencies.autoload_once_paths.delete(File.join(this_dir, 'portlet_test_bench'))
else
  ActiveSupport::Dependencies.load_once_paths.delete(File.join(this_dir, 'portlet_test_bench'))
end

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
