# This generator installs the required files into the main Rails application.
# This generator should always be run after upgrading the plugin.
class CaterpillarGenerator < Rails::Generator::Base
  def manifest

    require 'find'
    file = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
    this_dir = File.dirname(File.expand_path(file))
    tmpl = this_dir+'/templates'

    STDOUT.puts ' * Installing config and images'

    record do |m|

      ### config ###
      m.directory('config')
      file = 'portlets.rb'
      m.file('config/'+file, 'config/'+file)
      ####################################


# these are now cramped inline to the view partial
#       ### stylesheet ###
#       target = 'public/stylesheets/caterpillar'
#       m.directory(target)
#       file = 'caterpillar.css'
#       m.file('stylesheets/caterpillar/'+file, target+'/'+file)
#       ####################################
# 
#       ### javascript ###
#       target = 'public/javascripts/caterpillar'
#       m.directory(target)
#       file = 'caterpillar.js'
#       m.file('javascripts/caterpillar/'+file, target+'/'+file)
#       ####################################

      ### images ###
      target = 'public/images'
      m.directory(target)
      file = 'caterpillar.gif'
      m.file('images/caterpillar/'+file, target+'/'+file)
      ####################################

    end
  end
end
