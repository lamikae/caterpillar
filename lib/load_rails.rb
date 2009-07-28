# NOTE: During normal startup (not while building the gem),
# ActiveRecord should be loaded at this point, before loading any of the models.
# However, this may conflict later when Rails' rake task activates the boot process.
# The correct versions should be loaded at this point.
config_file = File.join(
  File.expand_path(RAILS_ROOT),
  'config',
  'environment.rb'
)
if $0[/gem$/] or !File.exist?(config_file)
  rails_gem_version = nil
else
  # Attempt to guess proper Rails version by reading Rails' config file
  f=File.open(config_file)
  config = f.read
  rails_gem_version = config[/RAILS_GEM_VERSION.*(\d\.\d\.\d)/,1]
  f.close
end

# Load the proper versions of Rails etc.
require 'rubygems'
%w{ activesupport actionpack activerecord }.each do |rg|
  gem(rg, '= '+rails_gem_version) if rails_gem_version
  require rg
end
require 'action_controller'
