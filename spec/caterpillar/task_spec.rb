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
  end

  after(:each) do
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
    rm_f fn
  end

end
