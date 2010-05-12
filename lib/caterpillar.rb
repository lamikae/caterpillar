# encoding: utf-8
#--
# (c) Copyright 2008-2010 Mikael Lammentausta
#                    2010 Túlio Ornelas
#
# See the file MIT-LICENSE included with the distribution for
# software license details.
#++

module Caterpillar
  VERSION='1.3.0'
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
# Maybe this is too heavy, as some tasks do not need any Rails modules.
require File.join(this_dir,'rails_gem_chooser')
RailsGemChooser.__load # detects the Rails config file from RAILS_ROOT

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
