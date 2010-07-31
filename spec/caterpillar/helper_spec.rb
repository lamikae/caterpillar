# encoding: utf-8
#--
# Copyright (c) 2010 Mikael Lammentausta
# This source code is available under the MIT license.
# See the file LICENSE.txt for details.
#++

require File.join(File.dirname(__FILE__),'..','spec_helper')
require File.join(File.dirname(__FILE__),'..','..','lib','caterpillar')
require File.join(File.dirname(__FILE__),'..','..','lib','caterpillar','helpers','liferay')

class MockController
  include Caterpillar::Helpers::Liferay
  attr_accessor :cookies
end


describe Caterpillar::Task do

  before(:all) do
  end

  before(:each) do
    @rake = Rake::Application.new
    Rake.application = @rake
    verbose(false)
    @task = Caterpillar::Task.new
  end

  after(:each) do
    @task = nil
  end

  it "should form resource url" do
    mock = MockController.new
    params = {:controller => MockController}
    resource_url = 'http://liferay-resource.url/'

    given_params = params.dup
    url = mock.liferay_resource_url(params, resource_url)
    params.should == given_params # original params should not change
    url.should == resource_url + '&railsRoute=/MockController/index'

    # test action
    params.update(:action => 'moo_action')
    given_params = params.dup
    url = mock.liferay_resource_url(params, resource_url)
    params.should == given_params # original params should not change
    url.should == resource_url + '&railsRoute=/MockController/moo_action'

    # test extra keys
    params.update(:foo => :bar, :baz => 3)
    given_params = params.dup
    url = mock.liferay_resource_url(params, resource_url)
    params.should == given_params # original params should not change
    url.should == resource_url + '&railsRoute=/MockController/moo_action?foo=bar&baz=3'

    # test resource url in cookie
    mock.cookies = {:Liferay_resourceUrl => resource_url}
    _url = mock.liferay_resource_url(params)
    url.should == _url
  end



end
