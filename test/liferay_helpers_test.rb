# encoding: utf-8


require 'test_helper'
require File.dirname(File.expand_path(__FILE__))+'/test_helper'

class LiferayHelpersTest < ActionController::TestCase # :nodoc:
  include Caterpillar::Helpers::Liferay
  
  def test_link_to_liferay
    #user = User.first
    #flunk
    assert true
  end
  
  def test_get_liferay_preferences
    # Simulated value from the cookie sent
    value = "font_size=20px;background_color=#000000;page_size=20;"
    
    hash = get_liferay_preferences(value)
    assert_not_nil hash
    assert_equal 3, hash.length
    [:font_size, :background_color, :page_size].each do |key|
      hash.has_key? key
    end
    
    ["20px", "#000000", "20"].each do |value|
      hash.has_value? value
    end
    
    assert_nil get_liferay_preferences(nil)
  end
  
  def test_liferay_resource_url
    # Simulated value from the cookie sent
    resource_url = "http://localhost:8080/resourceUrl"

    params = {
      :controller => :c1,
      :action     => :a1
    }
    
    # expected behavior
    url = liferay_resource_url(params, resource_url)
    assert_not_nil url
    assert_equal "#{resource_url}&railsRoute=/c1/a1", url
    
    params = {
      :controller => :c1
    }
    
    # expected behavior without :action param
    url = liferay_resource_url(params, resource_url)
    assert_not_nil url
    assert_equal "#{resource_url}&railsRoute=/c1/index", url
    
    # expected behavior without :controller
    params = {}
    url = liferay_resource_url(params, resource_url)
    assert_not_nil url
    assert_equal "#{resource_url}", url
    
    # expected behavior without resource_url
    assert_raise RuntimeError do
      liferay_resource_url(params, nil)
    end
  end
  
end
