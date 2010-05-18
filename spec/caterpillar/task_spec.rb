# encoding: utf-8
#--
# Copyright (c) 2010 Mikael Lammentausta
# This source code is available under the MIT license.
# See the file LICENSE.txt for details.
#++

require File.join(File.dirname(__FILE__),'..','spec_helper')
require File.join(File.dirname(__FILE__),'..','..','lib','caterpillar')

describe Caterpillar::Task do
  before(:each) do
    @rake = Rake::Application.new
    Rake.application = @rake
    verbose(false)
    @task = Caterpillar::Task.new
    @pwd = Dir.pwd
  end

  after(:each) do
    @task = nil
    rm_f '/tmp/portlets-config.rb'
    Dir.chdir @pwd
  end

  it "should print version" do
    capture { Rake::Task["version"].invoke }.should =~ /Caterpillar #{Caterpillar::VERSION}/
  end

  it "should create a conf file" do
    Dir.chdir('/tmp')
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

end
