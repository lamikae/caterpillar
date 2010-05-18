# encoding: utf-8


require 'rubygems'

# Rails gem chooser
#
# Requires the proper Rails version by the +RAILS_ROOT/config/environment.rb+ file.
class RailsGemChooser
  class << self

  def version(config_file=nil)
	unless config_file
	  config_file = File.join(
	  File.expand_path(RAILS_ROOT),
        'config',
        'environment.rb'
        )
	end
    # don't attempt to load Rails if building a Rubygem..!
    if $0[/gem$/] or !File.exist?(config_file)
      rails_gem_version = nil
    else
      # Attempt to guess proper Rails version by reading Rails' config file
      f=File.open(config_file)
      config = f.read
      rails_gem_version = config[/RAILS_GEM_VERSION.*(\d\.\d\.\d)/,1]
      f.close
      #STDOUT.puts 'Detected Rails version %s from the config file %s' % [rails_gem_version,config_file]
    end
    return rails_gem_version
  end

  # Load a specific GEM
  def __load_gem(require_name, gem_name, version)
    version ? gem(gem_name, '= '+version) : gem(gem_name)
    begin
      require require_name
    rescue LoadError
      require gem_name
    end
  end

  # Either define +rails_gem_version+ or +config_file+
  # Without any parameters, the config_file is detected from RAILS_ROOT.
  def __load(rails_gem_version=nil,config_file=nil)
    raise 'oops' if config_file and rails_gem_version

    rails_gem_version ||= version(config_file)

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

    # gem build fails when activesupport is loaded here
    # - except with Rails 2.3.5 where this needs to be added.
    if $0[/gem$/]
    #    rails_gems -= ['activesupport']
    end
    rails_gems.keys.each do |rg_key|
      __load_gem(rg_key, rails_gems[rg_key], rails_gem_version)
    end
    require 'action_controller'

    #STDOUT.puts 'Loaded Rails version %s' % Rails::VERSION::STRING
  end

  end
end
