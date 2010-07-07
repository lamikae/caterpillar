# encoding: utf-8


require 'test_helper'
require File.dirname(File.expand_path(__FILE__))+'/test_helper'

class PortletsTest < Caterpillar::TestCase # :nodoc:

#   def test_get
#     @portlets.each do |portlet|
#       next if portlet[:reqs].empty?
#       @controller = portlet[:reqs][:controller]
#       action = portlet[:reqs][:action]
#       get action
#     end
#   end

  def test_session
    key = Caterpillar::Security.get_session_key()
    assert_not_nil key
    secret = Caterpillar::Security.get_secret()
    assert_not_nil secret
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
