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

  def __load(config_file=nil)
    rails_gem_version = version(config_file)
    raise 'Rails version could not be detected!' unless rails_gem_version

    STDOUT.puts 'Loading Rails version %s' % rails_gem_version
    # gem build fails when activesupport is loaded here
    # %w{ activesupport actionpack activerecord }.each do |rg|
    %w{ actionpack activerecord }.each do |rg|
      gem(rg, '= '+rails_gem_version)
      require rg
    end
    require 'action_controller'
  end

  end
end