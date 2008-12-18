#--
# (c) Copyright 2008 Mikael Lammentausta
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
      @name   = name
      @config = Util.eval_configuration(config)
      yield self if block_given?
      send tasks
    end

    private

    def define_tasks
      define_main_task
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
      define_migrate_task
      define_rollback_task
      define_jar_install_task
      define_jar_uninstall_task
      define_jar_version_task
    end

    # the main XML generator task
    def define_main_task
      desc 'Create all XML files according to configuration'
      tasks = [:parse,"#{@name}:portlet"]
      if @config.container.kind_of? Liferay
        tasks << "#{@name}:liferayportletapp"
        tasks << "#{@name}:liferaydisplay"
      end
      tasks << "portlets" # finally print produced portlets
      task :xml => tasks
    end

    def define_usage_task
      task :usage do
        Usage.show
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

    # navigation debugging task
    def define_portlets_task
      desc 'Prints portlet configuration'
      task :portlets => :parse do
        print_portlets(@portlets)
      end
    end

  def define_fixtures_task
    desc 'Creates YAML fixtures from live data for testing.'
    task :fixtures => :environment do
      require 'active_record'

      sql = "SELECT * from %s"

      skip_tables = []
      begin
        skip_tables = @config.container.skip_fixture_tables
      end

      ActiveRecord::Base.establish_connection
      (ActiveRecord::Base.connection.tables - skip_tables).each do |table|
        i = "000"
        File.open("#{RAILS_ROOT}/test/fixtures/#{table}.yml", 'w') do |file|
          puts "* %s" % file.inspect
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
        file = 'portlet-ext.xml'
      else
        file = 'portlet.xml'
      end
      with_namespace_and_config do |name, config|
        desc 'Create JSR286 portlet XML'
        task :portlet do
          system('touch %s' % file)
          f=File.open(file,'w')
          f.write Portlet.xml(@portlets)
          f.close
          STDOUT.puts 'Created %s' % file
        end
      end
    end

    # Writes liferay-portlet-ext.xml
    def define_liferayportletappxml_task
      @name = :xml
      file = 'liferay-portlet-ext.xml'
      with_namespace_and_config do |name, config|
        desc 'Create Liferay portlet XML'
        task :liferayportletapp do
          system('touch %s' % file)
          f=File.open(file,'w')
          f.write config.container.portletapp_xml(@portlets)
          f.close
          STDOUT.puts 'Created %s' % file
        end
      end
    end

    # Writes liferay-display.xml
    def define_liferaydisplayxml_task
      @name = :xml
      file = 'liferay-display.xml'
      with_namespace_and_config do |name, config|
        desc 'Create Liferay display XML'
        task :liferaydisplay do
          system('touch %s' % file)
          f=File.open(file,'w')
          f.write config.container.display_xml(@portlets)
          f.close
          STDOUT.puts 'Created %s' % file
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


    def define_migrate_task
      @name = :db
      with_namespace_and_config do |name, config|
        desc "Migrates Caterpillar database tables"
        task :migrate => :environment do
          require 'active_record'
          ActiveRecord::Migrator.migrate(
            File.expand_path(
              File.dirname(__FILE__) + "/../../db/migrate"))
  #         Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby

          @portlets = config.container.analyze(:native)
          @portlets.each do |portlet|
            LiferayPortlet.create(
              :name => portlet[:name],
              :title => portlet[:title]
            )
          end
        end
      end
    end

    def define_rollback_task
      @name = :db
      with_namespace_and_config do |name, config|
        desc "Wipes out Caterpillar database tables"
        task :rollback => :environment do
          require 'active_record'
          version = ENV['VERSION'].to_i || 0
          ActiveRecord::Migrator.migrate(
            File.expand_path(
              File.dirname(__FILE__) + "/../../db/migrate"), version)
  #         Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
        end
      end
    end

    def define_jar_install_task
      @name = :jar
      with_namespace_and_config do |name, config|
        desc 'Installs Rails-portlet JAR into the portlet container'
        task :install do
          raise 'Only Liferay is supported' unless @config.container.kind_of? Liferay
          require 'find'

          portlet_jar = nil
          old_jar = nil
          version = nil
          source = File.join(CATERPILLAR_LIBS,'java')
          target = File.join(@config.container.WEB_INF,'lib')

          Find.find(source) do |file|
            if File.basename(file) =~ /rails-portlet/
              portlet_jar = file
              version = file[/(\d.\d.\d).jar/,1]
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

          info 'Installing Rails-portlet version %s to %s' % [version, target]
          system('cp %s %s' % [portlet_jar,target])
          if old_jar
            info 'Removing old version'
            system('rm -f %s' % old_jar)
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
          require 'find'
          target = File.join(@config.container.WEB_INF,'lib')

          Find.find(target) do |file|
            if File.basename(file) =~ /rails-portlet/
              version = file[/(\d.\d.\d).jar/,1]
              info 'Uninstalling Rails-portlet version %s from %s' % [version, target]
              system('rm -f %s' % file)
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

    def with_namespace_and_config
      name, config = @name, @config
      namespace name do
        yield name, config
      end
    end

    protected

    def print_portlets(hash)
      Util.categorize(hash).each_pair do |category,portlets|
        puts category
        portlets.each do |portlet|
          # spaces
          spaces = ''
          0.upto(50-portlet[:title].size+1) do
            spaces << ' '
          end

          field = :path
          puts "\t"+ portlet[:title] +spaces+ portlet[field].inspect
        end
      end
    end

    def info(msg)
      STDOUT.puts ' * ' + msg
    end



  end
end
