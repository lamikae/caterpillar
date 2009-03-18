#--
# (c) Copyright 2008,2009 Mikael Lammentausta
#
# Thanks to Nick Sieger for the rake structure!
#
# See the file LICENSES.txt included with the distribution for
# software license details.
#++

require 'rake'
require 'rake/tasklib'

require 'actionpack'
require 'action_controller'

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
      STDOUT.puts 'Caterpillar v.%s (c) Copyright 2008,2009 Mikael Lammentausta' % VERSION
      STDOUT.puts 'Provided under the terms of the MIT license.'
      STDOUT.puts
      @name   = name
      @config = Util.eval_configuration(config)
      @logger = @config.logger

      yield self if block_given?
      @xml_files = []

      send tasks
    end

    private

    def define_tasks
      define_xml_task
      define_usage_task
      define_config_task
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
    end

    def define_usage_task
      task :usage do
        Usage.show
      end
    end

    # TODO: copy and diff config file
    def define_config_task
      task :config do
        STDOUT.puts 'TODO'
      end
    end

    def define_pluginize_task
      desc "Unpack Caterpillar as a plugin in your Rails application"
      task :pluginize do
        if !Dir["vendor/plugins/caterpillar*"].empty?
          puts "I found an old nest in vendor/plugins; please trash it so I can make a new one"
          puts "(directory vendor/plugins/caterpillar* exists)"
        elsif !File.directory?("vendor/plugins")
          puts "I can't find a place to build my nest"
          puts "(directory 'vendor/plugins' is missing)"
        else
          Dir.chdir("vendor/plugins") do
            ruby "-S", "gem", "unpack", "caterpillar"
          end
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

      # print produced portlets
      tasks << :portlets

      task :xml => tasks
    end

    # Prints the list of portlets.
    def define_portlets_task
      desc 'Prints portlet configuration'
      task :portlets => :parse do
        portal_info
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

        (ActiveRecord::Base.connection.tables - skip_tables).each do |table|
          i = "000"
          File.open(
            File.join(RAILS_ROOT,'test','fixtures',table+'.yml'), 'w'
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

    ### SUB-TASKS

    # reads Rails environment configuration
    def define_environment_task
      task :default => :test
      task :environment do
        require(File.join(@config.rails_root, 'config', 'environment'))
        if @config.container.is_a?(Caterpillar::Liferay)
          @config.container.version ||= Lportal::Schema.version
          portal_info
        end
      end
    end

    # collects Rails' routes and parses the config
    def define_parse_task
      task :parse => :environment do
        @config.routes = Util.parse_routes(@config)
        @portlets = Parser.new(@config).portlets
      end
    end

    # Writes the portlet.xml file
    def define_portletxml_task
      @name = :xml
      # set the output filename
      if @config.container.kind_of? Liferay
        file = File.join('tmp','portlet-ext.xml')
      else
        file = File.join('tmp','portlet.xml')
      end
      @xml_files << file
      with_namespace_and_config do |name, config|
        desc 'Create JSR286 portlet XML'
        task :portlet do
          portal_info

          exit 1 unless system('touch %s' % file)
          f=File.open(file,'w')
          f.write Portlet.xml(@portlets)
          f.close
          info '-> %s' % file
        end
      end
    end

    # Writes liferay-portlet-ext.xml
    def define_liferayportletappxml_task
      @name = :xml
      file = File.join('tmp','liferay-portlet-ext.xml')
      @xml_files << file
      with_namespace_and_config do |name, config|
        desc 'Create Liferay portlet XML'
        task :liferayportletapp do
          exit 1 unless system('touch %s' % file)
          f=File.open(file,'w')
          f.write config.container.portletapp_xml(@portlets)
          f.close
          info '-> %s' % file
        end
      end
    end

    # Writes liferay-display.xml
    def define_liferaydisplayxml_task
      @name = :xml
      file = File.join('tmp','liferay-display.xml')
      @xml_files << file

      with_namespace_and_config do |name, config|
        desc 'Create Liferay display XML'
        task :liferaydisplay do
          raise 'Version 5.1.2 of Liferay is broken!' if config.container.version == '5.1.2'

          exit 1 unless system('touch %s' % file)
          f=File.open(file,'w')
          f.write config.container.display_xml(@portlets)
          f.close
          info '-> %s' % file
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
        desc "Migrates lportal and Caterpillar database tables"
        task :migrate => :environment do

          # first run lportal sequence migrations (TODO)
          info('Running lportal migrations')
          ActiveRecord::Migrator.migrate(LPORTAL_MIGRATIONS)

          # info('running Caterpillar migrations')
          # ActiveRecord::Migrator.migrate(
          #   File.expand_path(
          #     File.join(CATERPILLAR_LIBS,'..','db','migrate')))

          #Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
          info 'You need to manually run rake db:schema:dump'

          Rake::Task['db:update'].invoke
        end
      end
    end

    def define_db_rollback_task
      @name = :db
      with_namespace_and_config do |name, config|
        desc "Wipes out Caterpillar database tables"
        task :rollback => :environment do

          version = ENV['VERSION'].to_i || 0

          info('Reverting lportal migrations')
          ActiveRecord::Migrator.migrate(LPORTAL_MIGRATIONS, version)

          # info('Reverting Caterpillar migrations')
          # ActiveRecord::Migrator.migrate(
          #   File.expand_path(
          #     File.join(CATERPILLAR_LIBS,'..','db','migrate')), version)

          #Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
          info 'You need to manually run rake db:schema:dump'
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

          unless @config.container.kind_of? Liferay
            info 'Installation of the JAR is only supported on Liferay. Patches are welcome.'
            info 'Copy the JAR from this directory into the CLASSPATH of the portlet container.'
            info source
            exit 1
          end

          container_v = @config.container.version

          unless container_v
            info 'Unable to detect the version of the portlet container. Installing the latest version.'
          end

          version = (
            if container_v and container_v[/^5.1/]
              '0.6.0' #'0.5.2' # FIXME: branch properly
            else
              '0.6.1'
            end
          )

          portlet_jar = nil
          old_jar = nil
          target = File.join(@config.container.WEB_INF,'lib')

          # check that target exists
          unless File.exists?(target)
            info 'JAR directory %s does not exist' % target
            exit 1
          end

          require 'find'
          Find.find(source) do |file|
            if File.basename(file) =~ /rails-portlet-#{version}/
              portlet_jar = file
            end
          end

          # check for previous installs..
          Find.find(target) do |file|
            if File.basename(file) =~ /rails-portlet/
              old_version = file[/(\d.\d.\d).jar/,1]
              # check if there's an update available
              if version.gsub(/\./,'').to_i > old_version.gsub(/\./,'').to_i
                info 'Rails-portlet version %s is found, but an update is available.' % old_version
                old_jar = file
              else
                info 'Rails-portlet version %s is already installed.' % old_version
                exit 0
              end
            end
          end

          exit 1 unless system('cp %s %s' % [portlet_jar,target])
          info 'installed Rails-portlet version %s to %s' % [version, target]
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
          raise 'Only Liferay is supported' unless @config.container.kind_of? Liferay
          target = File.join(@config.container.WEB_INF,'lib')

          # check that target exists
          unless File.exists?(target)
            info 'JAR directory %s does not exist' % target
            exit 1
          end

          require 'find'
          Find.find(target) do |file|
            if File.basename(file) =~ /rails-portlet/
              version = file[/(\d.\d.\d).jar/,1]
              info 'Uninstalling Rails-portlet version %s from %s' % [version, target]
              exit 1 unless system('rm -f %s' % file)
              exit 0
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
        desc 'Checks the installed Rails-portlet version'
        task :version do
          raise 'Only Liferay is supported' unless @config.container.kind_of? Liferay
          require 'find'
          target = File.join(@config.container.WEB_INF,'lib')

          Find.find(target) do |file|
            if File.basename(file) =~ /rails-portlet/
              version = file[/(\d.\d.\d).jar/,1]
              info 'Rails-portlet version %s found in %s' % [version, target]
              exit 0
            end
          end

          info 'Rails-portlet was not found in %s' % target
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
        info 'Building WAR using Warbler %s on JRuby %i (%s)' % [
          Warbler::VERSION, JRUBY_VERSION, jruby]
        info ''
        exit 1 unless system(jruby+' -S warble war')
        info 'Warbler finished successfully'
      end
    end

    def define_deploy_task
      desc 'Deploy XML files and the application WAR to the portlet container'

      tasks = ['db:update', :xml, :warble, 'deploy:xml', 'deploy:war']
      task :deploy => tasks
    end

    def define_deploy_xml_task
      @name = :deploy
      with_namespace_and_config do |name, config|
        desc 'Deploys the XML files'
        task :xml do
          raise 'Only deployment to Liferay on Tomcat is supported' unless @config.container.kind_of? Liferay
          target = @config.container.WEB_INF
          info 'deploying XML files to %s' % target

          @xml_files.each do |file|
            exit 1 unless system('cp %s %s' % [file,target])
            info ' %s' % [file]
          end
        end
      end
    end
    def define_deploy_war_task
      @name = :deploy
      with_namespace_and_config do |name, config|
        desc 'Deploys the WAR file'
        task :war do
          raise 'Only deployment to Liferay on Tomcat is supported' unless @config.container.kind_of? Liferay
          file = @config.servlet+'.war'
          unless File.exists?(file)
            info 'cannot find the WAR file %s, exiting' % file
            exit 1
          end

          target = File.join(@config.container.root,'webapps')

          info '..removing previous installs..'
          exit 1 unless system('rm -rf %s' % File.join(target,@config.servlet+'*'))

          info 'deploying the WAR package to %s' % target
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

    protected

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
        STDOUT.puts category
        portlets.each do |portlet|
          # spaces
          spaces = ''
          0.upto((longest_title + 5)-portlet[:title].size) do
            spaces << ' '
          end

          #field = :path
          #fields = [:name, :id]
          STDOUT.puts "\t" + portlet[:title] +spaces+ portlet[:id].inspect + "\t" + portlet[:name].inspect
        end
      end
    end

    def info(msg)
      STDOUT.puts ' * ' + msg
    end

    def portal_info(config=@config)
      msg = 'Caterpillar configured for %s version %s at %s' % [
        config.container.name, config.container.version, config.container.root
      ]
      @logger ? @logger.info(msg) : STDOUT.puts(msg)
    end



  end
end
