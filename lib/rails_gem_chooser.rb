# encoding: utf-8
#--
# (c) Copyright 2009 - 2011 Mikael Lammentausta
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
      rails_gem_version = config[/^RAILS_GEM_VERSION.*(\d\.\d\.\d+)/,1]
      #STDOUT.puts 'Detected Rails version %s from the config file %s' % [rails_gem_version,config_file]
      return rails_gem_version
    end
  end

  # Load a specific GEM
  def __load_gem(require_name, gem_name, version)
    #STDOUT.puts 'Loading gem: %s v %s' % [require_name, version]
    version ? gem(gem_name, '= '+version) : gem(gem_name)
    begin
      require require_name
    rescue LoadError
      require gem_name
    end
  end

  # Either define +rails_gem_version+ or +config_file+
  def __load(rails_gem_version=nil,config_file=nil)
    if (config_file and rails_gem_version) and (version != rails_gem_version)
      raise 'oops: Rails version mismatch'
    end

    rails_gem_version ||= version(config_file) # also detects ENV['RAILS_GEM_VERSION']

    #STDOUT.puts 'Loading Rails version %s' % rails_gem_version
    # the gem without underline will be removed in Rails3..
    #rails_gems = %w{ active_support action_pack active_record }
    # except that with the underline divider the gem is not found ..
    #rails_gems = %w{ activesupport actionpack activerecord }
    
    rails_gems = {
      # require name      gem name
      "active_support" => "activesupport",
      "action_pack"    => "actionpack",
      "active_record"  => "activerecord"
    }

    rails_gems.keys.each do |rg_key|
      __load_gem(rg_key, rails_gems[rg_key], rails_gem_version)
    end
    require 'action_controller' # action_controller lives in action_pack

    #STDOUT.puts "Loaded gems:"
    #STDOUT.puts "ActiveRecord: %s" % ActiveRecord::VERSION::STRING
    #STDOUT.puts "ActionPack: %s" %  ActionPack::VERSION::STRING
    #require 'active_support/version'
    #STDOUT.puts "ActiveSupport: %s" %  ActiveSupport::VERSION::STRING
  end

  end
end
