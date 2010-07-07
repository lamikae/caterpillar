# encoding: utf-8

require 'test_helper'
require File.dirname(File.expand_path(__FILE__))+'/test_helper'

require 'libxml'

class XmlTest < Caterpillar::TestCase # :nodoc:

  def setup
    super
    @dtd_dir = File.dirname(File.expand_path(__FILE__)) + '/dtd'
    # what DTD version to match against:
    # Liferay version => DTD version
    @liferay_tld_table = {
      '5.1.1' => '5.1.0',
      '5.2.0' => '5.2.0',
      '5.2.3' => '5.2.0',
      '6.0.1' => '6.0.0'
    }
  end

  def test_portlet_elements
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

    xml = Caterpillar::Portlet.portlet_element(portlet).to_s
    assert xml[/#{portlet[:name]}/]
    assert xml[/#{portlet[:title]}/]
    assert !xml[/secret/]

    xml = Caterpillar::Portlet.portlet_element(portlet,session).to_s
    assert xml[/#{session[:secret]}/], 'No secret'

    xml = Caterpillar::Portlet.filter_element(portlet).to_s
    assert xml[/#{portlet[:servlet]}/]
    assert xml[/#{portlet[:path]}/]
  end

  def test_session_key
    key = Caterpillar::Security.get_session_key
    assert_not_nil key
  end

  def test_secret
    secret = Caterpillar::Security.get_secret
    assert_not_nil secret
  end

  def test_portlet_xml
    xml = Caterpillar::Portlet.xml(@portlets)

    # parse xml document
    doc = LibXML::XML::Parser.string(xml).parse

    schema = LibXML::XML::Schema.new(File.join(@dtd_dir,'portlet-app_2_0.xsd'))
    assert doc.validate_schema(schema)
  end

  def test_liferay_display_xml
    @liferay_tld_table.each_pair do |version,tld|
      @config.container.version = version
      xml = @config.container.display_xml(@portlets)

      dtd_v = xml[/liferay-display_(._._.)/,1]
      assert_equal(tld.gsub('.','_'), dtd_v, 'Failed to create DTD with proper version')

      # parse DTD
      dtd_file = File.join(@dtd_dir,'liferay-display_%s.dtd' % tld.gsub('.','_'))
      dtd = LibXML::XML::Dtd.new(File.read(dtd_file))

      # parse xml document
      doc = LibXML::XML::Parser.string(xml).parse

      # validate
      assert doc.validate(dtd)
    end
  end

  def test_liferay_portlet_xml
    @liferay_tld_table.each_pair do |version,tld|
      @config.container.version = version
      xml = @config.container.portletapp_xml(@portlets)
      dtd_v = xml[/liferay-portlet-app_(._._.)/,1]
      assert_equal(tld.gsub('.','_'), dtd_v, 'Failed to create DTD with proper version')

      # parse DTD
      dtd_file = File.join(@dtd_dir,'liferay-portlet-app_%s.dtd' % tld.gsub('.','_'))
      dtd = LibXML::XML::Dtd.new(File.read(dtd_file))

      # parse xml document
      doc = LibXML::XML::Parser.string(xml).parse

      # validate
      assert doc.validate(dtd)
    end
  end
  
  def test_public_render_parameters_xml
    doc = REXML::Document.new
    doc << REXML::XMLDecl.new('1.0', 'utf-8') 
    app = REXML::Element.new('portlet-app', doc)
    app.attributes['version'] = '2.0'
    app.attributes['xmlns'] = 'http://java.sun.com/xml/ns/portlet/portlet-app_2_0.xsd'
    app.attributes['xmlns:xsi'] = 'http://www.w3.org/2001/XMLSchema-instance'
    app.attributes['xsi:schemaLocation'] = 'http://java.sun.com/xml/ns/portlet/portlet-app_2_0.xsd'
    
    portlet = {
      :name  => "test_portlet",
      :path => "/test/path",
      :public_render_parameters => [:tag, :folksonomy]
    }
          
    element = Caterpillar::Portlet.portlet_element(portlet, nil, app)
    xml = element.to_s
    assert_not_nil xml
    assert !xml.empty?

    assert xml[/#{portlet[:name]}/]
    assert xml[/#{portlet[:title]}/]
    assert xml[/#{portlet[:servlet]}/]
    assert !xml[/secret/]
          
    element = Caterpillar::Portlet.portlet_element(portlet, nil, app)
    xml = element.to_s
    assert_not_nil xml
    assert !xml.empty?

    portlet[:public_render_parameters].each do |param|
      assert xml[/#{param}/]
    end
    
    assert xml[/<supported-public-render-parameter>/]
    assert app.to_s[/<public-render-parameter>/]
  end

end





































