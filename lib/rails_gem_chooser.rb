# encoding: utf-8
#--
# (c) Copyright 2009,2010 Mikael Lammentausta
#
# See the file MIT-LICENSE included with the distribution for
# software license details.
#++

require 'rubygems'

# Rails gem chooser.
#
# Selects RAILS_GEM_VERSION from ENV, or from RAILS_ROOT/config/environment.rb.
# Returns nil otherwise.
class RailsGemChooser
  class << self

  def version(config_file=nil)
    # detect from ENV
    if ENV['RAILS_GEM_VERSION']
      return ENV['RAILS_GEM_VERSION']
    elsif not config_file
      # load Rails config file
      if RAILS_ROOT
          config_file = File.join(
          File.expand_path(RAILS_ROOT),
            'config',
            'environment.rb'
            )
      else
        STDERR.puts 'Could not detect Rails version'
        return nil
      end
	end
    # don't attempt to load Rails if building a Rubygem..!
    if $0[/gem$/] or !File.exist?(config_file)
      return nil
    else
      # read from Rails config file
      f=File.open(config_file)
      config = f.read
      f.close
      rails_gem_version = config[/^RAILS_GEM_VERSION.*(\d\.\d\.\d)/,1]
      STDOUT.puts 'Detected Rails version %s from the config file %s' % [rails_gem_version,config_file]
      return rails_gem_version
    end
  end

  # Load a specific GEM
  def __load_gem(name,version)
    #p 'require gem %s v%s' % [name,version]
    version ? gem(name, '= '+version) : gem(name)
    require name
  end

  # Either define +rails_gem_version+ or +config_file+
  def __load(rails_gem_version=nil,config_file=nil)
    raise 'oops' if config_file and rails_gem_version

    rails_gem_version ||= version(config_file) # also detects ENV['RAILS_GEM_VERSION']

    #STDOUT.puts 'Loading Rails version %s' % rails_gem_version

    # XXX: silly hack because gem loading seems to have a problem..
    # >> gem('active_support', '=2.3.5')
    # Gem::LoadError: Could not find RubyGem active_support (= 2.3.5)
    # >> require 'activesupport'
    # DEPRECATION WARNING: require "activesupport" is deprecated and will be removed in Rails 3. Use require "active_support" instead..
    require 'active_support' 
    rails_gems = %w{ actionpack activerecord }

    ActiveSupport::Deprecation.silence do
      rails_gems.each do |rg|
        __load_gem(rg,rails_gem_version)
      end
    end
    require 'action_controller'

    #STDOUT.puts 'Loaded Rails version %s' % Rails::VERSION::STRING
  end

  end
end
