file = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
this_dir = File.dirname(File.expand_path(file))

# append the views path
ActionController::Base.append_view_path File.join(this_dir, 'views')

# load the main file
require File.join(this_dir, 'lib', 'caterpillar')
