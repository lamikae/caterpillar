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
module Caterpillar # :nodoc:
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
    # Defines the rake task prefix 'jsr'.
    def initialize(name = :jsr, config = nil, tasks = :define_tasks)
      @name   = name
      @config = Util.eval_configuration(config)

      yield self if block_given?
      send tasks
    end

    private

    def define_tasks
      define_main_task
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
    end

    # the main XML generator task
    def define_main_task
      desc 'Create all XML files according to configuration'
      tasks = [:parse,"#{@name}:portletxml"]
      if @config.container.kind_of? Liferay
        tasks << "#{@name}:liferayportletappxml"
        tasks << "#{@name}:liferaydisplayxml"
      end
      tasks << "portlets" # finally print produced portlets
      task :jsr => tasks
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
      # set the output filename
      if @config.container.kind_of? Liferay
        file = 'portlet-ext.xml'
      else
        file = 'portlet.xml'
      end
      with_namespace_and_config do |name, config|
        desc "Create JSR286 portlet XML"
        task "portletxml" do
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
      file = 'liferay-portlet-ext.xml'
      with_namespace_and_config do |name, config|
        desc 'Create Liferay portlet XML'
        task "liferayportletappxml" do
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
      file = 'liferay-display.xml'
      with_namespace_and_config do |name, config|
        desc "Create Liferay display XML"
        task "liferaydisplayxml" do
          system('touch %s' % file)
          f=File.open(file,'w')
          f.write config.container.display_xml(@portlets)
          f.close
          STDOUT.puts 'Created %s' % file
        end
      end
    end

    def define_liferayportlets_task
      with_namespace_and_config do |name, config|
        desc 'Analyses native Liferay portlets XML'
        task "portlets" do
          @portlets = config.container.analyze(:native)
          print_portlets(@portlets)
        end
      end
    end


    def define_migrate_task
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



  end
end