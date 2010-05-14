# encoding: utf-8


#--
# (c) Copyright 2008, 2010 Mikael Lammentausta
# See the file LICENSES.txt included with the distribution for
# software license details.
#++

module Caterpillar
  # Formulates generic JSR286 portlet XML
  class Portlet
    class << self

    # Creates portlet XML
    def xml(portlets)
    	session = 
        begin
          {
            :key    => Caterpillar::Security.get_session_key(),
            :secret => Caterpillar::Security.get_secret()
          }
        rescue nil
        end
        
      xml = self.header
      portlets.each do |p|
        xml << self.template(p,session)
      end
      xml << self.footer
      return xml
    end

    def debug(config,routes) # :nodoc:
      routes.select{|r| !r[:name].empty?}.each do |route|
        puts '%s: %s' % [route[:name], route[:path]]
      end
    end

    # Rails-portlet Java class
    def portlet_class
      'com.celamanzi.liferay.portlets.rails286.Rails286Portlet'
    end

    # Rails-portlet Java class for 0.10.0+
    def portlet_filter_class
      'com.celamanzi.liferay.portlets.rails286.Rails286PortletFilter'
    end

    # JSR 286 portlet XML header. Opens portlet-app.
    def header
      xml =  '<?xml version="1.0" encoding="UTF-8"?>' +"\n"
      xml << '<portlet-app xmlns="http://java.sun.com/xml/ns/portlet/portlet-app_2_0.xsd"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xsi:schemaLocation="http://java.sun.com/xml/ns/portlet/portlet-app_2_0.xsd"
             version="2.0">'
      xml << "\n\n"
      return xml
    end

    # Closes portlet-app.
    def footer
      '</portlet-app>' + "\n"
    end

    # portlet.xml template.
    # session is a hash containing session key and secret from Rails.
    def template(portlet,session=nil)
      # add roles
      # TODO: move into portlet hash
      # administrator, power-user, user
      roles = %w{ administrator }
      xml =  "  <!-- %s -->\n" % portlet[:title]

      xml << "  <portlet>\n"
      ### identification
      xml << "    <portlet-name>%s</portlet-name>\n" % portlet[:name]
      xml << "    <portlet-class>%s</portlet-class>\n" % self.portlet_class
      ### supported portlet modes
      xml << "    <supports>\n"
      xml << "      <mime-type>text/html</mime-type>\n"
      xml << "      <portlet-mode>view</portlet-mode>\n"
      if portlet[:edit_mode] == true
        xml << "      <portlet-mode>edit</portlet-mode>\n"
      end
      xml << "    </supports>\n"
      
      # Public Render Parameters
      if portlet[:public_render_parameters] and portlet[:public_render_parameters].length > 0
        portlet[:public_render_parameters].each do |param|
          xml << "    <supported-public-render-parameter>\n"
          xml << "      #{param}\n"
          xml << "    </supported-public-render-parameter>\n"
        end
      end
      
      ### title for portlet container
      xml << "    <portlet-info>\n"
      xml << "      <title>%s</title>\n" % portlet[:title]
      xml << "    </portlet-info>\n"
      # insert session key
      unless session.nil?
        xml << "    <init-param>\n"+\
               "      <name>session_key</name>\n"+\
               "      <value>#{session[:key]}</value>\n"+\
               "    </init-param>\n"
      end
      # insert secret
      unless session.nil?
        xml << "    <init-param>\n"+\
               "      <name>secret</name>\n"+\
               "      <value>#{session[:secret]}</value>\n"+\
               "    </init-param>\n"
      end
      roles.each do |role|
        xml << "    <security-role-ref>\n"
        xml << "      <role-name>#{role}</role-name>\n"
        xml << "    </security-role-ref>\n"
      end
      xml << "  </portlet>\n\n"

      ### portlet filters
      xml << "  <filter>\n"
      # the filter reads the settings and sets the portlet session
      xml << "    <filter-name>%s_filter</filter-name>\n" % portlet[:name]
      xml << "    <filter-class>%s</filter-class>\n" % self.portlet_filter_class
      xml << "    <lifecycle>RENDER_PHASE</lifecycle>\n"
      xml << "    <lifecycle>RESOURCE_PHASE</lifecycle>\n"
      # define host, servlet and route (path to be more precise)
      xml << "    <init-param>\n"
      xml << "      <name>host</name>\n"
      xml << "      <value>%s</value>\n" % portlet[:host] || ""
      xml << "    </init-param>\n"
      xml << "    <init-param>\n"
      xml << "      <name>servlet</name>\n"
      xml << "      <value>%s</value>\n" % portlet[:servlet]
      xml << "    </init-param>\n"
      xml << "    <init-param>\n"
      xml << "      <name>route</name>\n"
      xml << "      <value>%s</value>\n" % portlet[:path].gsub(/&/,"&amp;")
      xml << "    </init-param>\n"
      xml << "  </filter>\n\n"

      xml << "  <filter-mapping>\n"
      xml << "    <filter-name>%s_filter</filter-name>\n" % portlet[:name]
      xml << "    <portlet-name>%s</portlet-name>\n" % portlet[:name]
      xml << "  </filter-mapping>\n"
      xml << "\n"
    end

  end # static methods
  end
end
