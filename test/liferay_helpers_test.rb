# encoding: utf-8


require 'test_helper'
require File.dirname(File.expand_path(__FILE__))+'/test_helper'

class LiferayHelpersTest < ActionController::TestCase # :nodoc:
  include Caterpillar::Helpers::Liferay


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

  def test_liferay_ResourceUrl_model
    resource_url_cookie = 'http://localhost:8080/web/guest/test?p_p_id=portlet_test_bench&p_p_lifecycle=2&p_p_state=normal&p_p_mode=view&p_p_cacheability=cacheLevelPage&p_p_col_id=column-2&p_p_col_count=1&_portlet_test_bench_railsRoute=caterpillar/test_bench/xhr/resource'
    #options = {
    #  :controller => 'Caterpillar::XhrController',
    #  :action     => :resource
    #}
    #url_for in ResourceUrl can't handle modularized controllers, use explicit route as workaround
    options = { :route => 'caterpillar/test_bench/xhr/resource' }
    namespace = 'portlet_test_bench'
    
    res = Caterpillar::Helpers::Liferay::ResourceUrl.new(
      resource_url_cookie, namespace)
    res.options = options
    assert_equal(resource_url_cookie, res.to_s)
  end

  def test_liferay_ResourceUrl_model_with_params
    resource_url_cookie = 'http://localhost:8080/web/guest/test?p_p_id=portlet_test_bench&p_p_lifecycle=2&p_p_state=normal&p_p_mode=view&p_p_cacheability=cacheLevelPage&p_p_col_id=column-2&p_p_col_count=1&_portlet_test_bench_railsRoute=caterpillar/test_bench/xhr/resource'
    #url_for in ResourceUrl can't handle modularized controllers..
    options = { :route => 'caterpillar/test_bench/xhr/index' }
    params = {:foo => :bar}
    namespace = 'portlet_test_bench'
    
    res = Caterpillar::Helpers::Liferay::ResourceUrl.new(
      resource_url_cookie, namespace)
    res.options = options
    res.params = params
    assert_equal('http://localhost:8080/web/guest/test?p_p_id=portlet_test_bench&p_p_lifecycle=2&p_p_state=normal&p_p_mode=view&p_p_cacheability=cacheLevelPage&p_p_col_id=column-2&p_p_col_count=1&_portlet_test_bench_railsRoute=caterpillar/test_bench/xhr/index&_portlet_test_bench_foo=bar', res.to_s)
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
    assert_equal "#{resource_url}?__railsRoute=/c1/a1", url
    
    params = {
      :controller => :c1
    }
    
    # expected behavior without :action param
    url = liferay_resource_url(params, resource_url)
    assert_not_nil url
    assert_equal "#{resource_url}?__railsRoute=/c1", url
    
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
