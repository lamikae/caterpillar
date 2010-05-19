# encoding: utf-8
#--
# Copyright (c) 2010 Mikael Lammentausta
# This source code is available under the MIT license.
# See the file LICENSE.txt for details.
#++

require File.join(File.dirname(__FILE__),'..','spec_helper')
require File.join(File.dirname(__FILE__),'..','..','lib','caterpillar')
require 'tmpdir'

describe Caterpillar::Task do
  before(:each) do
    @rake = Rake::Application.new
    Rake.application = @rake
    verbose(false)
    @task = Caterpillar::Task.new
    @pwd = Dir.pwd
    @tmpdir = Dir.tmpdir + '/caterpillar'
    Dir.mkdir(@tmpdir) unless File.exists?(@tmpdir)
  end

  after(:each) do
    @task = nil
    FileUtils.rm_rf @tmpdir
    Dir.chdir @pwd
  end

  it "should print version" do
    capture { Rake::Task["version"].invoke }.should =~ /Caterpillar #{Caterpillar::VERSION}/
  end

  it "should create a conf file" do
    Dir.chdir(@tmpdir)
    fn = "portlets-config.rb"
    File.exist?(fn).should == false
    silence { Rake::Task["generate"].invoke }
    File.exist?(fn).should == true
  end

  it "should print no route" do
    portlet = {
        :name     => 'portlet_test_bench',
    }
    @task.config.instances << portlet
    capture { Rake::Task["portlets"].invoke }.should =~ /no route for portlet_test_bench/
  end

  it "should print routes" do
    portlet = {
        :name     => 'portlet_test_bench',
    }
    @task.config.instances << portlet
    @task.config.rails_root = File.join(File.dirname(__FILE__),'..','app1')
    capture { Rake::Task["portlets"].invoke }.should =~ /\/caterpillar\/test_bench/
  end

  it "should parse routes without config.rails_root" do
    portlet = {
        :name     => 'portlet_test_bench',
        :rails_root => File.join(File.dirname(__FILE__),'..','app1')
    }
    @task.config.instances << portlet
    capture { Rake::Task["portlets"].invoke }.should =~ /\/caterpillar\/test_bench/
  end

  it "should parse routes" do
    config = Caterpillar::Config.new
    config.rails_root = File.join(File.dirname(__FILE__),'..','app3')
    config.instances = [
    {
        :name     => 'portlet_test_bench',
        :title    => 'Rails-portlet test bench',
        :category => 'Caterpillar',
        :rails_root => File.join(File.dirname(__FILE__),'..','app1')
    },
    {
        :name     => 'hungry_bear',
        :rails_root => File.join(File.dirname(__FILE__),'..','app2')
    },
    {
        :name     => 'adorabe_otters'
    }
    ]
    routes = Caterpillar::Util.parse_routes(config)
    routes.size.should == 4 # test bench twice

    routes[0][:path].should == '/caterpillar/test_bench'
    routes[0][:reqs][:controller].should == 'Caterpillar::Application'
    routes[0][:reqs][:action].should == 'index'

    routes[1][:path].should == '/caterpillar/test_bench'
    routes[1][:reqs][:controller].should == 'Caterpillar::Application'
    routes[1][:reqs][:action].should == 'index'

    routes[2][:path].should == '/bear/hungry'
    routes[2][:reqs][:controller].should == 'Bear'
    routes[2][:reqs][:action].should == 'hungry'

    routes[3][:path].should == '/otters/adorable'
    routes[3][:reqs][:controller].should == 'Otter'
    routes[3][:reqs][:action].should == 'adorable'
  end

  it "should define Tomcat WEB-INF location" do
    container_root = @tmpdir

    @task.config.container = Caterpillar::Liferay
    @task.config.container.root = container_root
    @task.config.container.root.should == container_root

    @task.config.container.server = 'Tomcat'
    FileUtils.mkdir_p(container_root+'/webapps')
    @task.config.container.deploy_dir.should == container_root + '/webapps' 
    @task.config.container.WEB_INF().should == container_root + '/webapps/ROOT/WEB-INF'
  end

  it "should define JBoss/Tomcat WEB-INF location" do
    container_root = @tmpdir

    @task.config.container = Caterpillar::Liferay
    @task.config.container.root = container_root
    @task.config.container.root.should == container_root

    @task.config.container.server = 'JBoss/Tomcat'
    FileUtils.mkdir_p(container_root+'/server/ROOT.war/deploy')
    @task.config.container.deploy_dir.should == container_root + '/server/ROOT.war/deploy' 
    @task.config.container.server_dir.should == 'ROOT.war'
    # XXX: this is broken
    @task.config.container.WEB_INF.should == container_root + '/server/ROOT.war/deploy/WEB-INF'
  end

  it "should make XML" do
    portlet = {:name => 'portlet_test_bench'}
    @task.config.instances << portlet

    Dir.chdir(@tmpdir)
    Dir.glob('*.xml').size.should == 0

    silence { Rake::Task["makexml"].invoke }

    File.exists?('portlet-ext.xml').should == true
    File.exists?('liferay-portlet-ext.xml').should == true
    File.exists?('liferay-display.xml').should == true
  end

  it "should deploy XML on Tomcat" do
    portlet = {:name => 'portlet_test_bench'}
    @task.config.instances << portlet

    container_root = @tmpdir
    @task.config.container.root = container_root
    @task.config.container.server = 'Tomcat'

    web_inf = container_root + '/webapps/ROOT/WEB-INF'
    @task.config.container.WEB_INF.should == web_inf

    File.exists?(web_inf).should == false
    FileUtils.mkdir_p(web_inf)
    File.exists?(web_inf).should == true

    silence { Rake::Task["deploy:xml"].invoke }

    Dir.chdir(web_inf)
    File.exists?('portlet-ext.xml').should == true
    File.exists?('liferay-portlet-ext.xml').should == true
    File.exists?('liferay-display.xml').should == true
  end

end
