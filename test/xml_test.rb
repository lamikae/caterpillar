require 'test_helper'
require File.dirname(File.expand_path(__FILE__))+'/test_helper'

class XmlTest < Caterpillar::TestCase # :nodoc:

  def test_portlet_xml
    xml = Caterpillar::Portlet.xml(@portlets)
    assert_not_nil xml
    assert !xml.empty?
  end

  def test_liferay_display_xml
    xml = Caterpillar::Liferay.new(@config).display_xml(@portlets)
    assert_not_nil xml
    assert !xml.empty?
  end

  def test_liferay_portlet_xml
    xml = Caterpillar::Liferay.new(@config).portletapp_xml(@portlets)
    assert_not_nil xml
    assert !xml.empty?
  end

end