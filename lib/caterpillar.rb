# encoding: utf-8
#--
# (c) Copyright 2008 - 2011 Mikael Lammentausta
#               2010 Tulio Ornelas dos Santos
#
# See the file MIT-LICENSE included with the distribution for
# software license details.
#++

module Caterpillar
  VERSION = '1.6.0' unless defined? Caterpillar::VERSION
end

STDOUT.puts 'Caterpillar: version %s' % Caterpillar::VERSION

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

require File.join(this_dir,'rails_gem_chooser')

if (defined? RAILS_ROOT)
  # ActiveRecord should be loaded at this point, before loading any of the models.
  # However, this may conflict later when Rails' rake task activates the boot process.
  # The correct versions should be loaded at this point.
  RailsGemChooser.__load # detects the Rails config file from RAILS_ROOT
end

# include all ruby files
%w{
  config
  util
  usage
  task
  security
  portlet_support
  portlet
  parser
  navigation
  liferay
}.each do |src|
  require File.join(this_dir, 'caterpillar', src+'.rb')
end

# these are used in Rails environment
if (defined? RAILS_ENV)
  require File.join(this_dir, 'web', 'portlet.rb')
  require File.join(this_dir, 'caterpillar', 'helpers', 'portlet.rb')
  require File.join(this_dir, 'caterpillar', 'helpers', 'liferay.rb')
end
