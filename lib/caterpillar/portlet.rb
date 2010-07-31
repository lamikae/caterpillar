# encoding: utf-8
#--
# (c) Copyright 2008, 2010 Mikael Lammentausta
#                     2010 Tulio Ornelas
# See the file MIT-LICENSE included with the distribution for
# software license details.
#++
          
if RUBY_PLATFORM =~ /java/
  gem 'jrexml'
  require 'jrexml'
else
  require "rexml/document"
end

module Caterpillar

  # Formulates generic JSR286 portlet XML
  class Portlet
    class << self

    # Rails-portlet Java class
    def portlet_class
      'com.celamanzi.liferay.portlets.rails286.Rails286Portlet'
    end

    # Rails-portlet Java class for 0.10.0+
    def portlet_filter_class
      'com.celamanzi.liferay.portlets.rails286.Rails286PortletFilter'
    end

    # Creates <portlet-app> XML document for portlet-ext.xml.
    #
    # @param portlets is an Array of Hashes
    # @returns String
    def xml(portlets)
      # create a new XML document
      doc = REXML::Document.new
      doc << REXML::XMLDecl.new('1.0', 'utf-8') 
      app = REXML::Element.new('portlet-app', doc)
      app.attributes['version'] = '2.0'
      app.attributes['xmlns'] = 'http://java.sun.com/xml/ns/portlet/portlet-app_2_0.xsd'
      app.attributes['xmlns:xsi'] = 'http://www.w3.org/2001/XMLSchema-instance'
      app.attributes['xsi:schemaLocation'] = 'http://java.sun.com/xml/ns/portlet/portlet-app_2_0.xsd'

      # create session values, common for all portlets
      session = 
        begin
          {
            :key    => Caterpillar::Security.get_session_key(),
            :secret => Caterpillar::Security.get_secret()
          }
        rescue
          nil
        end

      # create XML element tree
      # (in proper order so the validation passes)
      portlets.each do |portlet|
        # <portlet>
        app.elements << self.portlet_element(portlet, session, app)
      end
      portlets.each do |portlet|
        # <filter>
        app.elements << self.filter_element(portlet)
      end
      portlets.each do |portlet|
        # filter mapping
        app.elements << self.filter_mapping(portlet)
      end
      return Util.xml_to_s(doc)
    end

    # <portlet> element.
    # session is a hash containing session key and secret from Rails.
    def portlet_element(portlet, session = nil, app = nil)            
      element = REXML::Element.new('portlet')
      # NOTE: to pass validation, the elements need to be in proper order!
                                                              
      REXML::Element.new('portlet-name', element).text = portlet[:name]
      REXML::Element.new('portlet-class', element).text = self.portlet_class

      # insert session key
      unless session.nil?
        param = REXML::Element.new('init-param', element)
        REXML::Element.new('name', param).text = 'session_key'
        REXML::Element.new('value', param).text = session[:key]

        param = REXML::Element.new('init-param', element)
        REXML::Element.new('name', param).text = 'secret'
        REXML::Element.new('value', param).text = session[:secret]
      end

      supports = REXML::Element.new('supports', element)
      REXML::Element.new('mime-type', supports).text = 'text/html'
      ### supported portlet modes
      REXML::Element.new('portlet-mode', supports).text = 'view'
      if portlet[:edit_mode] == true
        REXML::Element.new('portlet-mode', supports).text = 'edit'
      end
                           
      # Public Render Parameters
      if portlet[:public_render_parameters] and portlet[:public_render_parameters].length > 0
        portlet[:public_render_parameters].each do |param|
          REXML::Element.new('supported-public-render-parameter', element).text = param
        end
      end

      info = REXML::Element.new('portlet-info', element)
      ### title for portlet container
      REXML::Element.new('title', info).text = portlet[:title]

      # add roles
      # TODO: move into portlet hash
      # administrator, power-user, user
      roles = %w{ administrator }
      roles.each do |role|
        ref = REXML::Element.new('security-role-ref', element)
        REXML::Element.new('role-name', ref).text = role
      end

      # Public Render Parameters
      if (not app.nil?) and portlet[:public_render_parameters] and portlet[:public_render_parameters].length > 0
        portlet[:public_render_parameters].each do |param|
          prp = REXML::Element.new('public-render-parameter', app)
          REXML::Element.new('identifier', prp).text = param
          qname = REXML::Element.new('qname', prp)
          qname.text = "x:#{param}"
          qname.attributes['xmlns:x'] = 'http://www.liferay.com/public-render-parameters' 
        end
      end
      
      return element
    end

    # <filter> element.
    def filter_element(portlet)
      # the filter reads the settings and sets the portlet session
      element = REXML::Element.new('filter')

      REXML::Element.new('filter-name', element).text = "#{portlet[:name]}_filter"
      REXML::Element.new('filter-class', element).text = self.portlet_filter_class
      REXML::Element.new('lifecycle', element).text = 'RENDER_PHASE'
      REXML::Element.new('lifecycle', element).text = 'RESOURCE_PHASE'

      # define host, servlet and route (path to be more precise)
      param = REXML::Element.new('init-param', element)
      REXML::Element.new('name', param).text = 'host'
      REXML::Element.new('value', param).text = portlet[:host]

      param = REXML::Element.new('init-param', element)
      REXML::Element.new('name', param).text = 'servlet'
      REXML::Element.new('value', param).text = portlet[:servlet]

      param = REXML::Element.new('init-param', element)
      REXML::Element.new('name', param).text = 'route'
      portlet_path = portlet[:path].gsub(/&/,"&amp;")
      REXML::Element.new('value', param).text = portlet_path
                                  
      if portlet[:edit_mode] == true
        param = REXML::Element.new('init-param', element)
        REXML::Element.new('name', param).text = 'preferences_route'
        
        if portlet[:preferences_route]
          preferences_route = portlet[:preferences_route]
        else
          preferences_route = portlet_path.gsub(':controller', portlet[:defaults][:controller])
          preferences_route = preferences_route.gsub(':action', 'preferences')
        end
        REXML::Element.new('value', param).text = preferences_route
      end

      return element
    end

    # <filter-mapping> element.
    def filter_mapping(portlet)
      element = REXML::Element.new('filter-mapping')

      REXML::Element.new('filter-name', element).text = "#{portlet[:name]}_filter"
      REXML::Element.new('portlet-name', element).text = portlet[:name]

      return element
    end

    def debug(config,routes) # :nodoc:
      routes.select{|r| !r[:name].empty?}.each do |route|
        puts '%s: %s' % [route[:name], route[:path]]
      end
    end

  end # static methods
  end
end
