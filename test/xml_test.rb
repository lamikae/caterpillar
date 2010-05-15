# encoding: utf-8

require 'test_helper'
require File.dirname(File.expand_path(__FILE__))+'/test_helper'

require 'libxml'

class XmlTest < Caterpillar::TestCase # :nodoc:

  def setup
    super
    @dtd_dir = File.dirname(File.expand_path(__FILE__)) + '/dtd'
  end

  def test_portlet_xml
    xml = Caterpillar::Portlet.xml(@portlets)
    assert_not_nil xml
    assert !xml.empty?        
    assert xml[/secret/]
  end
  
  def test_portlet_template
    portlet = {
      :name  => "some name",
      :title => "some title",
      :servlet => "Test",
      :path => "/test/path"
    }
    
    session = {
      :key    => '_test_session',
      :secret => 'XXX'
    }
    
    xml = Caterpillar::Portlet.template(portlet)
    assert_not_nil xml
    assert !xml.empty?

    assert xml[/#{portlet[:name]}/]
    assert xml[/#{portlet[:title]}/]
    assert xml[/#{portlet[:servlet]}/]
    assert xml[/#{portlet[:path]}/]
    assert !xml[/secret/]

    xml = Caterpillar::Portlet.template(portlet,session)
    assert_not_nil xml
    assert !xml.empty?

    assert xml[/#{session[:secret]}/]
  end

  def test_session_key
    key = Caterpillar::Security.get_session_key
    assert_not_nil key
  end
  
  def test_secret
    secret = Caterpillar::Security.get_secret
    assert_not_nil secret
  end
  

  def test_liferay_display_xml
# FIXME
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

      # parse DTD
      dtd_file = File.join(@dtd_dir,'liferay-portlet-app_%s.dtd' % tld.gsub('.','_'))
      dtd = LibXML::XML::Dtd.new(File.read(dtd_file))

      # parse xml document to be validated
      doc = LibXML::XML::Parser.string(xml).parse

      # validate
      assert doc.validate(dtd)
    end
  end

end
