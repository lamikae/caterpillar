#--
# (c) Copyright 2008,2009 Mikael Lammentausta
# See the file LICENSES.txt included with the distribution for
# software license details.
#++

module Caterpillar
  VERSION='1.0.0'
end

this_file = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
this_dir = File.dirname(File.expand_path(this_file))

CATERPILLAR_LIBS=this_dir unless defined?(CATERPILLAR_LIBS)

RAILS_ROOT = Dir.pwd unless defined? RAILS_ROOT

require 'find'
require 'rake'
require 'rake/tasklib'

# NOTE: During normal startup (not while building the gem),
# ActiveRecord should be loaded at this point, before loading any of the models.
# However, this may conflict later when Rails' rake task activates the boot process.
# The correct versions should be loaded at this point.
# Otherwise only one version of Rails & co. rubygems should exist on the system.

if $0[/gem$/]
  rails_gem_version = nil
else
  # Attempt to guess proper Rails version by reading Rails' config file
  f=File.open(
    File.join(
      File.expand_path(RAILS_ROOT),
      'config',
      'environment.rb'
    )
  )
  config = f.read
  rails_gem_version = config[/RAILS_GEM_VERSION.*(\d\.\d\.\d)/,1]
  f.close
end

  # Load the proper versions of Rails etc.
  # Not tested on all setups.
  require 'rubygems'
  ['activesupport',
  'actionpack',
  'activerecord'].each { |rg|
    gem(rg, '= '+rails_gem_version) if rails_gem_version
    require rg
  }
  require 'action_controller'

# include all ruby files
Find.find(this_dir) do |file|
  if FileTest.directory?(file)
    if File.basename(file) == 'deprecated'
      Find.prune # Don't look any further into this directory.

    # load helpers only in Rails environment
    elsif (!defined?(RAILS_ENV) and (File.basename(file) == 'helpers'))
      Find.prune

    else
      next
    end
  else
    # do not require this file twice
    require file if file[/.rb$/] and File.basename(file) != File.basename(this_file)
  end
end
