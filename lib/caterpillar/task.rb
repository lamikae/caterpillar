# encoding: utf-8
#--
# (c) Copyright 2008,2009,2010 Mikael Lammentausta
#
# Thanks to Nick Sieger for the rake structure!
#
# See the file MIT-LICENSE included with the distribution for
# software license details.
#++

# --
# Rake task.  Allows defining multiple configurations inside the same
# Rakefile by using different task names.
# ++
module Caterpillar
  class << self
    attr_writer :project_application
    def project_application
      @project_application || Rake.application
    end
  end

  class Task < Rake::TaskLib

    # Task name
    attr_accessor :name

    # Config
    attr_accessor :config

    # Portlets
    attr_reader :portlets

    # The main task.
    # Reads the configuration file and launches appropriate tasks.
    def initialize(name = :usage, config = nil, tasks = :define_tasks)
      @name   = name

      @config = (name == 'rails' or name == 'version' ) ? Config.new(false) : Util.eval_configuration(config)
      @logger = @config.logger

      @xml_files = []

      if name == 'rails'
        @required_gems = %w(rails caterpillar jruby-jars warbler)
      else
        if not @config and not %w{generate version}.include?(name)
          Usage.show()
          exit 1
        end
      end

      yield self if block_given?
      send tasks
    end

    private

    def define_tasks
      define_version_task
      define_xml_task
      define_usage_task
      define_pluginize_task
      define_environment_task
      define_portletxml_task
      define_liferayportletappxml_task
      define_liferaydisplayxml_task
      define_parse_task
      define_portlets_task
      define_fixtures_task
      define_liferayportlets_task
      define_db_migrate_task
      define_db_rollback_task
      define_db_update_task
      define_jar_install_task
      define_jar_uninstall_task
      define_jar_version_task
      define_warble_task
      define_deploy_task
      define_deploy_xml_task
      define_deploy_war_task
      define_rails_task
      define_generate_task
    end

    def define_usage_task
      task :usage => :version do
        Usage.show
      end
    end

    def define_version_task
      task :version do
        version_str = "Caterpillar #{Caterpillar::VERSION} "
        version_str << "Ruby #{RUBY_VERSION} "
        if RUBY_PLATFORM =~ /java/
          version_str << "JRuby #{JRUBY_VERSION}"
        end
        $stdout.puts version_str
      end
    end

    def define_pluginize_task
      desc "Unpack Caterpillar to your Rails application"
      task :pluginize do
        if !Dir["vendor/plugins/caterpillar*"].empty? && ENV["FORCE"].nil?
          puts "I found an old pupa"
          puts "(directory vendor/plugins/caterpillar* exists);"
          puts "please trash it so I can make a new one,"
          puts "or prepend the command with environment variable FORCE=1."
          exit 1
        elsif !File.directory?("vendor/plugins")
          puts "I can't find a place to build my pupa"
          puts "(directory 'vendor/plugins' is missing)"
          exit 1
        else
          rm_rf FileList["vendor/plugins/caterpillar*"], :verbose => false
          ruby "-S", "gem", "unpack", "caterpillar", "--target", "vendor/plugins"
          # rename the versioned name to plain "caterpillar",
          # since Rails has trouble loading some helper files without so
          File.rename(
            "vendor/plugins/caterpillar-#{Caterpillar::VERSION}",
            "vendor/plugins/caterpillar")
          ruby "./script/generate caterpillar"
        end
      end
    end


    ### MAIN TASKS

    # Main XML generator task
    def define_xml_task
      @name = :xml
      desc 'Create all XML files according to configuration'
      tasks = [:parse,"#{@name}:portlet"]
      if @config.container.kind_of? Liferay
        tasks << "#{@name}:liferayportletapp"
        tasks << "#{@name}:liferaydisplay"
      end              
      
      task :makexml => tasks
      #puts 'Done!'
    end

    # Prints the list of portlets.
    def define_portlets_task
      desc 'Prints portlet configuration'
      task :portlets => :parse do
        #portal_info
        info 'Portlet configuration ***********************'
        print_portlets(@portlets)
      end
    end

    # Creates live fixtures from the RAILS_ENV database for testing.
    def define_fixtures_task
      desc 'Creates YAML fixtures from live data for testing.'
      task :fixtures => :environment do

        sql = "SELECT * from %s"

        skip_tables = []
        begin
          skip_tables = @config.container.skip_fixture_tables
        end

        ActiveRecord::Base.establish_connection
        info 'Creating YAML fixtures from %s database' % RAILS_ENV

        # define and create the target directory
        target = 
          (defined? RAILS_ROOT) ?
            File.join(RAILS_ROOT,'test','fixtures') : 'fixtures'
        if !File.exists?(target)
          FileUtils.mkdir_p(target)
        end

        (ActiveRecord::Base.connection.tables - skip_tables).each do |table|
          i = "000"
          File.open(
            File.join(target,table+'.yml'), 'w'
          ) do |file|
            info file.inspect
            data = ActiveRecord::Base.connection.select_all(sql % table)
            file.write data.inject({}) { |hash, record|
              hash["#{table}_#{i.succ!}"] = record
              hash
            }.to_yaml
          end
        end
      end
    end

    def define_generate_task
      @name = :generate
      desc 'Generates stand-alone configuration file'
      task :generate do
        filename = 'portlets-config.rb'
        FileUtils.cp(
          File.expand_path(File.join(__FILE__,
            %w{.. .. .. generators caterpillar templates config portlets.rb})),
          filename
          )
        info("Generated #{filename}")
      end
    end

    ### SUB-TASKS

    # reads Rails environment configuration
    def define_environment_task
      task :environment do
        begin
          require(File.join(@config.rails_root, 'config', 'environment'))
        rescue
          raise 'Rails environment could not be loaded'
        end
        if @config.container.is_a?(Caterpillar::Liferay)
          if @config.container.version.nil? and !defined?(Lportal)
            $stderr.puts 'Liferay version is undefined, and lportal gem is not present.'
            $stderr.puts 'Please define portlet.container.version in %s.' % @config.class::FILE
            raise 'Insufficient configuration'
          end
          @config.container.version ||= Lportal::Schema.version
          portal_info
        end
      end
    end

    # collects Rails' routes and parses the config
    def define_parse_task
      task :parse do
        @config.routes = Util.parse_routes(@config)
        @portlets = Parser.new(@config).portlets
      end
    end

    # Writes the portlet.xml file
    def define_portletxml_task
      @name = :xml
      # set the output filename
      if @config.container.kind_of? Liferay
        file = 'portlet-ext.xml'
      else
        file = 'portlet.xml'
      end
      @xml_files << file
      with_namespace_and_config do |name, config|
        desc 'Create JSR286 portlet XML'
        task :portlet do
          #portal_info

          FileUtils.touch(file)
          f=File.open(file,'w')
          f.write Portlet.xml(@portlets)
          f.close
          #info '-> %s' % file
        end
      end
    end

    # Writes liferay-portlet-ext.xml
    def define_liferayportletappxml_task
      @name = :xml
      file = 'liferay-portlet-ext.xml'
      @xml_files << file
      with_namespace_and_config do |name, config|
        desc 'Create Liferay portlet XML'
        task :liferayportletapp do
          FileUtils.touch(file)
          f=File.open(file,'w')
          f.write config.container.portletapp_xml(@portlets)
          f.close
          #info '-> %s' % file
        end
      end
    end

    # Writes liferay-display.xml
    def define_liferaydisplayxml_task
      @name = :xml
      file = 'liferay-display.xml'
      @xml_files << file

      with_namespace_and_config do |name, config|
        desc 'Create Liferay display XML'
        task :liferaydisplay do
          raise 'Version 5.1.2 of Liferay is broken!' if config.container.version == '5.1.2'

          FileUtils.touch(file)
          f=File.open(file,'w')
          f.write config.container.display_xml(@portlets)
          f.close
          #info '-> %s' % file
        end
      end
    end

    def define_liferayportlets_task
      @name = :liferay
      with_namespace_and_config do |name, config|
        desc 'Analyses native Liferay portlet-display XML'
        task :portlets do
          @portlets = config.container.analyze(:native)
          print_portlets(@portlets)
        end
      end
    end


    ### MIGRATIONS AND JAR-INSTALL

    def define_db_migrate_task
      @name = :db
      with_namespace_and_config do |name, config|
        desc "Migrates lportal database tables"
        task :migrate => :environment do
          info 'TODO: use lportal Rake task'
          return
        end
      end
    end

    def define_db_rollback_task
      @name = :db
      with_namespace_and_config do |name, config|
        desc "Wipes out lportal database tables"
        task :rollback => :environment do
          info 'TODO: use lportal Rake task'
          return
        end
      end
    end

    def define_db_update_task
      @name = :db
      with_namespace_and_config do |name, config|
        desc 'Updates the portletproperties table'
        task :update => :environment do

          info 'analyzing portlet XML configuration'
          @portlets = config.container.analyze(:native)

          info 'updating database'
          Web::PortletProperties.all.each(&:destroy)
          @portlets.each do |portlet|
            Web::PortletProperties.create(
              :portletid    => portlet[:id],
              :name         => portlet[:name],
              :title        => portlet[:title],
              :instanceable => portlet[:instanceable]
            )
          end
        end
      end
    end

    # Install the Rails-portlet JAR
    def define_jar_install_task
      @name = :jar
      with_namespace_and_config do |name, config|
        desc 'Installs Rails-portlet JAR into the portlet container'
        task :install => :environment do
          source = File.join(CATERPILLAR_LIBS,'java')

          # detect (Liferay) container version
          container_v = @config.container.version
          unless container_v
            info 'Unable to detect the version of the portlet container. Installing the latest version.'
          end

          # detect the version of the JAR to install
          portlet_jar = nil
          # XXX: since the filter name has changed, the old JAR does not work
          #version = (
          #  if container_v and container_v[/^5.1/]
          #    '0.6.0' # FIXME: branch properly
          #  else
          #    '0.10.0'
          #  end
          #)
          version = '0.10.1'
          require 'find'
          Find.find(source) do |file|
            if File.basename(file) == "rails-portlet-#{version}.jar"
              portlet_jar = file
            end
          end

          # check if requirements match
          unless deployment_requirements_met?
            info 'Installation of the JAR is only supported on Liferay on Tomcat. Patches are welcome.'
            info 'Copy this JAR into the CLASSPATH of the portlet container.'
            info portlet_jar
            exit 1
          end

          old_jar = nil
          target = File.join(@config.container.WEB_INF,'lib')

          # check that target exists
          unless File.exists?(target)
            info 'JAR directory %s does not exist' % target
            exit 1
          end

          # check for previous installs..
          Find.find(target) do |file|
            if File.basename(file) =~ /rails-portlet/
              old_version = file[/(\d.\d*.\d).jar/,1]
              # check if there's an update available
              if version.gsub(/\./,'').to_i > old_version.gsub(/\./,'').to_i
                info 'Rails-portlet version %s is found, but an update is available' % old_version
                old_jar = file
              else
                info 'Rails-portlet version %s is already installed' % [old_version]
				info "\t" + file
                exit 0
              end
            end
          end

          exit 1 unless system('cp %s %s' % [portlet_jar,target])
          info 'installed Rails-portlet version %s' % [version]
				info "\t" + File.join(target,File.basename(portlet_jar))
          if old_jar
            exit 1 unless system('rm -f %s' % old_jar)
            info '..removed the old version %s' % old_jar
          end

        end
      end
    end

    def define_jar_uninstall_task
      @name = :jar
      with_namespace_and_config do |name, config|
        desc 'Uninstalls Rails-portlet JAR from the portlet container'
        task :uninstall do
          raise 'Only Liferay is supported' unless deployment_requirements_met?
          target = File.join(@config.container.WEB_INF,'lib')

          # check that target exists
          unless File.exists?(target)
            info 'JAR directory %s does not exist' % target
            exit 1
          end

          require 'find'
          Find.find(target) do |file|
            if File.basename(file) =~ /rails-portlet/
              version = file[/(\d.\d*.\d).jar/,1]
              info 'Uninstalling Rails-portlet JAR version %s from %s' % [version, target]
              exit File.delete(file)
            end
          end

          info 'Rails-portlet was not found in %s' % target
          exit 1
        end
      end
    end

    def define_jar_version_task
      @name = :jar
      with_namespace_and_config do |name, config|
        desc 'Checks the installed Rails-portlet JAR version'
        task :version do
          raise 'Only Liferay is supported' unless deployment_requirements_met?
          require 'find'
          target = File.join(@config.container.WEB_INF,'lib')

          Find.find(target) do |file|
            if File.basename(file) =~ /rails-portlet/
              version = file[/(\d.\d*.\d).jar/,1]
              info 'Rails-portlet version %s found: %s' % [version, file]
              exit 0
            end
          end

          info 'Rails-portlet JAR was not found in %s' % target
          exit 1
        end
      end
    end


    # Using JRuby to build the WAR file is necessary, as MRI Ruby can build broken files, even with the same set of rubygems.
    # Especially gettext seems to be a problem.
    def define_warble_task
      desc 'Create a WAR package with Warbler'
      task :warble do
        jruby_home = (ENV['JRUBY_HOME'] || @config.class::JRUBY_HOME)
        unless jruby_home
          info 'JRUBY_HOME is not set.'
          info 'First preference is the environment variable JRUBY_HOME.'
          info ' `export JRUBY_HOME="/usr/local/jruby"` and `sudo -E caterpillar %s`' % ARGV[0]
          info 'Another option is to define portlet.class::JRUBY_HOME in %s.' % @config.class::FILE
          exit 1
        end
        jruby = File.join(jruby_home,'bin','jruby')
        unless File.exists?(jruby)
          info 'JRuby executable was not found in %s, exiting' % jruby
          exit 1
        end
        begin
          require 'warbler'
        rescue
          info 'Warbler module was not found, exiting. Install Warbler for JRuby.'
          exit 1
        end
        unless File.exists?(@config.warbler_conf)
          info 'Warbler configuration file %s was not found, exiting' % @config.warbler_conf
          exit 1
        end
        info 'Building WAR using Warbler %s on JRuby at %s' % [
          Warbler::VERSION, jruby]
        info ''
        exit 1 unless system(jruby+' -S warble war')
        info 'Warbler finished successfully'
      end
    end

    def define_deploy_task
      desc 'Deploy XML files and the application WAR to the portlet container'
      tasks = []

      # only update the DB if the lportal gem is loaded
      tasks << 'db:update' if defined?(Lportal)

      ['deploy:xml', 'warble', 'deploy:war'].each { |task| tasks << task }
      task :deploy => tasks
    end

    def define_deploy_xml_task
      @name = :deploy
      with_namespace_and_config do |name, config|
        desc 'Builds and deploys the XML files'
        task :xml => 'makexml' do
          unless deployment_requirements_met?
            info 'Deployment is only supported on Liferay on Tomcat. Patches are welcome.'
            info 'Copy these XML files into the portlet container\'s WEB-INF.'
            @xml_files.each { |f| info f }
            exit 1
          end

          target = @config.container.WEB_INF
          info 'deploying XML files'

          @xml_files.each do |file|
            FileUtils.cp(file,target)
            info "-> " + File.join(target, File.basename(file))
          end
        end
      end
    end

    def define_deploy_war_task
      @name = :deploy
      with_namespace_and_config do |name, config|
        desc 'Deploys the WAR file'
        task :war do
          file = 
          	if @config.servlet.any?
            	@config.servlet + '.war'
            else
            	File.basename(Dir.pwd) + '.war'
            end
          unless File.exists?(file)
            info 'cannot find the WAR file %s, exiting' % file
            exit 1
          end

          # check if requirements match
          unless deployment_requirements_met?
            info 'Deployment is only supported on Liferay on Tomcat. Patches are welcome.'
            info 'Copy this WAR file into the portlet container\'s deployment directory.'
            info file
            exit 1
          end

          target = @config.container.deploy_dir

          if File.exists?(File.join(target,File.basename(file)))
            info '..removing previous installs..'
            exit 1 unless system('rm -rf %s' % File.join(target,@config.servlet+'*'))
          end

          info 'deploying the WAR package to %s' % File.join(target,file)
          exit 1 unless system('cp %s %s' % [file,target])

        end
      end
    end

    def with_namespace_and_config
      name, config = @name, @config
      namespace name do
        yield name, config
      end
    end

    def define_rails_task
      task :rails do
        exit 1 unless conferring_step 'Checking for required gems...' do 
          check_required_gems
        end
        exit 1 unless conferring_step 'Checking for JRuby binary...' do
          check_jruby
        end
        exit 1 unless conferring_step 'Checking for required gems in JRuby...' do
          check_jruby_required_gems
        end
        exit 1 unless conferring_step 'Creating Rails project...' do
          create_rails_project
          Dir.chdir("#{ARGV[1]}"){system("ruby script/generate html_template >/dev/null")}
        end
        exit 1 unless conferring_step 'Updating config/environment.rb...' do
          update_environment(ARGV[1] + '/config/environment.rb')
        end
        exit 1 unless conferring_step 'Activating caterpillar...' do
          # Rake::Task['pluginize'].execute         
          Dir.chdir("#{ARGV[1]}/vendor/plugins"){system 'ruby -S gem unpack caterpillar >/dev/null'}
          Dir.chdir("#{ARGV[1]}"){system 'ruby script/generate caterpillar >/dev/null'}
        end
        exit 1 unless conferring_step 'Configuring warbler...' do
          Dir.chdir("#{ARGV[1]}"){system 'ruby -S warble config >/dev/null 2>&1'}
          update_warble(ARGV[1] +'/config/warble.rb' , ARGV[1].split('/')[-1])
        end
      end
    end

    protected

    def deployment_requirements_met?
      @config.container.kind_of? Liferay and (
        @config.container.server == 'Tomcat' or
        @config.container.server == 'JBoss/Tomcat'
      )
    end

    def print_portlets(hash)
      # organize
      _sorted = Util.categorize(hash)

      # calculate the longest title
      longest_title = 0
      _sorted.each_pair do |category,portlets|
        x = portlets.sort_by{|p| p[:title].size}.last[:title]
        longest_title = x.size if x.size > longest_title
      end

      _sorted.each_pair do |category,portlets|
        $stdout.puts category
        portlets.each do |portlet|
          # spaces
          spaces = ''
          0.upto((longest_title + 5)-portlet[:title].size) do
            spaces << ' '
          end

          #field = :path
          #fields = [:name, :id]
          $stdout.puts "\t" + portlet[:title] +spaces+ portlet[:path] # + "\t" + portlet[:vars].inspect
        end
      end
    end

    def info(msg)
      $stdout.puts ' * ' + msg
    end

    def portal_info(config=@config)
      msg = 'Caterpillar %s configured for %s version %s at %s' % [
        Caterpillar::VERSION,
        config.container.name,
        config.container.version,
        config.container.root
      ]
      info(msg)
    end

    private

    def check_required_gems
      gems = @required_gems
      available_gems = []

      gems.each {|gem| available_gems << gem if Gem::available? gem}
      gems_not_found = (gems - available_gems)

      if gems_not_found.empty?
        return true
      else
        return "These required gems were not found: #{gems_not_found.join(' ')}\n" +
          "Please install them with: ruby -S gem install #{gems_not_found.join(' ')}"
      end
    end

    def check_jruby
      has_jruby = system 'jruby --copyright >/dev/null 2>&1'
      
      if has_jruby
        return true
      else
        return "jruby binary was not found in your path\n" +
          "Please visit: http://jruby.org/"
      end
    end

    def check_jruby_required_gems
      jruby_gems = `jruby -S gem list`
      available_gems = []
      
      @required_gems.each {|gem| available_gems << gem if jruby_gems.match(gem)}
      gems_not_found = (@required_gems - available_gems)

      if gems_not_found.empty?
        return true
      else
        return "These required gems were not found: #{gems_not_found.join(' ')}\n" +
          "Please install them with: jruby -S gem install #{gems_not_found.join(' ')}"
      end
    end

    def create_rails_project
      return 'specify rails project name' if ARGV[1].nil?
      return "#{ARGV[1]} folder name already exists" if FileTest.exists? ARGV[1]
      return system "ruby -S rails #{ARGV[1]} >/dev/null"
    end

    def update_environment(file_path)
      file = File.read(file_path).
          sub(/([ ]*#[ ]*config\.gem)/,
            "  config.gem 'caterpillar', :version => '>= #{Caterpillar::VERSION}'\n" + '\1')
      File.open(file_path, 'w') {|f| f << file}
    end

    def update_warble(file_path, project_name)
      file = File.read(file_path).
          sub(/([ ]*#[ ]*config\.war_name = \"mywar\")/,
            "  config.war_name = '#{project_name}-portlet'\n")
      File.open(file_path, 'w') {|f| f << file}
    end
    

    def conferring_step(message)
      $stdout.print message
      $stdout.flush
      
      result = yield
      if result.class == String or result.class == NilClass
        $stdout.puts "\e[31mFAILED\e[0m"
        puts result unless result.nil?
        return false
      else
        $stdout.puts "\e[32mOK\e[0m"
        return true
      end
    end
      
  end
end
