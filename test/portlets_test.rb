# encoding: utf-8


require 'test_helper'
require File.dirname(File.expand_path(__FILE__))+'/test_helper'

class PortletsTest < Caterpillar::TestCase # :nodoc:

  def test_session
    assert_not_nil @config.session_secret, 'No session secret in portlets.rb config'

    key = @config.session_secret[:key]
    assert_not_nil key
    secret = @config.session_secret[:secret]
    assert_not_nil secret
    assert_not_equal 'somereallylongrandomkey', secret,
      'Please generate your private random shared secret!'
  end

  def test_name
    @portlets.each do |portlet|
      assert_not_nil portlet[:name], '%s has no name' % portlet
    end
  end

  def test_path
    @portlets.each do |portlet|
      assert_not_nil portlet[:path], '%s has no path' % portlet[:name]
    end
  end

  def test_reqs
    @portlets.each do |portlet|
      assert_not_nil portlet[:reqs], '%s has no reqs' % portlet[:name]
    end
  end

  def test_vars
    valid_variables = [:gid] # the rails-portlet can handle these
    @portlets.each do |portlet|
      assert_not_nil portlet[:vars], '%s has no vars' % portlet[:name]
      portlet[:vars].each do |var|
	unless valid_variables.include?(var)
		'%s is not supported by Rails-portlet' % var
	end
      end
    end
  end

end
