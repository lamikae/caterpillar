# encoding: utf-8


# This generator installs the required files into the main Rails application.
# This generator should always be run after upgrading the plugin.
class CaterpillarGenerator < Rails::Generator::Base
  
  attr_accessor :project_name
  
  def msg(txt)
    _txt = " *\n"
    txt.split("\n").each do |line|
      _txt << " * %s\n" % line
    end
    _txt << " *\n"
    STDOUT.puts _txt
    STDOUT.flush
  end

  def after_generate
    # generate random shared secret
    msg(
      "Generating new random shared secret to config/portlets.rb"
    )
    File.open(File.join('config','portlets.rb'), "r+") do |f|
      newconf = f.read().sub('somereallylongrandomkey', Caterpillar::Security::random_secret)
      f.seek 0
      f.write newconf
    end

    msg(
      "If you want to use the portlet test bench,\n" + \
      "put the following line in your config/routes.rb before other routes.\n" + \
      "  map.caterpillar"
    )
  end

  def manifest
    require 'find'
    file = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
    this_dir = File.dirname(File.expand_path(file))
    tmpl = File.join(this_dir,'templates')

    @project_name = RAILS_ROOT.split('/')[-1]
    msg 'Installing configuration file with images, stylesheets and javascripts.'

    record do |m|

      ### config ###
      file = File.join('config','portlets.rb')
      m.template(file,file)

      ### Navigation ###
      target = File.join('public','images')
      m.directory(target)
      file = 'caterpillar.gif'
      m.file(File.join('images','caterpillar',file), File.join(target,file))

      ### Test bench ###
      testb = 'portlet_test_bench'
      
      #
      # images
      #
      target = File.join('public','images',testb)
      m.directory(target)
      Find.find(File.join(tmpl,'images',testb)) do |file|
        if FileTest.directory?(file)
          next
        else
          img = File.basename(file)
          next unless img[/(.jpg|.png|.gif)$/]
          m.file(File.join('images',testb,img), File.join(target,img))
        end
      end
      
      #
      # stylesheets
      #
      target = File.join('public','stylesheets',testb)
      m.directory(target)
      file = 'main.css'
      m.file(File.join('stylesheets',testb,file), File.join(target,file))
      
      #
      # javascripts
      #
      target = File.join('public','javascripts',testb)
      m.directory(target)
      file = 'main.js'
      m.file(File.join('javascripts',testb,file), File.join(target,file))

    end
  end
end
