# encoding: utf-8
#--
# (c) Copyright 2008-2010 Mikael Lammentausta
#                    2010 Tulio Ornelas
#
# See the file MIT-LICENSE included with the distribution for
# software license details.
#++

module Caterpillar   
  VERSION = '1.5.0-git' unless defined? Caterpillar::VERSION
end

this_file = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
this_dir = File.dirname(File.expand_path(this_file))

CATERPILLAR_LIBS = this_dir unless defined? CATERPILLAR_LIBS

# detect if running in Rails directory
if not defined? RAILS_ROOT
  rails_conf = File.join(Dir.pwd,'config','environment.rb')
  if File.exists?(rails_conf)
     # read from Rails config file
     f=File.open(rails_conf)
     _config = f.read
     f.close
     RAILS_ROOT = Dir.pwd if _config[/RAILS/]
  end
end

require 'find'
require 'rake'
require 'rake/tasklib'

if defined? RAILS_ROOT
	# NOTE: During normal startup (not while building the gem),
	# ActiveRecord should be loaded at this point, before loading any of the models.
	# However, this may conflict later when Rails' rake task activates the boot process.
	# The correct versions should be loaded at this point.
	require File.join(this_dir,'rails_gem_chooser')
	RailsGemChooser.__load # detects the Rails config file from RAILS_ROOT
end

# include all ruby files
Find.find(this_dir) do |file|
  if FileTest.directory?(file)
    if File.basename(file) == 'deprecated'
      Find.prune # Don't look any further into this directory.

    # load helpers only in Rails environment
    elsif (not defined?(RAILS_ENV) and %w{web helpers}.include?(File.basename(file)))
      Find.prune

    else
      next
    end
  else
    # do not require this file twice
    require file if file[/.rb$/] and File.basename(file) != File.basename(this_file)
  end
end
