require 'test_helper'
require File.dirname(File.expand_path(__FILE__))+'/test_helper'

class XmlTest < Caterpillar::TestCase # :nodoc:

  def test_portlet_xml
    xml = Caterpillar::Portlet.xml(@portlets)
    assert_not_nil xml
    assert !xml.empty?
  end

  def test_liferay_display_xml
#    xml = @config.container.display_xml(@portlets)
#    assert_not_nil xml
#    assert !xml.empty?
  end

  def test_liferay_portlet_xml
    { '5.1.1' => '5.1.0',
      '5.2.0' => '5.2.0' }.each_pair do |version,tld|

      @config.container.version = version
      xml = @config.container.portletapp_xml(@portlets)
      assert_not_nil xml
      assert !xml.empty?
      assert_not_nil xml[/liferay-portlet-app.*#{tld}/], 'Failed to create DTD with proper version; liferay %s' % version
    end
  end



end
