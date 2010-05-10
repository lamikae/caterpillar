require 'test_helper'
require File.dirname(File.expand_path(__FILE__))+'/test_helper'

class PortletSupportTest < ActionController::TestCase # :nodoc:
  include Caterpillar::PortletSupport
  
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
  
end
