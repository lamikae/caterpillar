#--
# (c) Copyright 2008 Mikael Lammentausta
# See the file LICENSES.txt included with the distribution for
# software license details.
#++

module Caterpillar
  # Formulates generic JSR286 portlet XML
  class Portlet
    class << self

    # Creates portlet XML
    def xml(portlets)
      xml = self.header
      portlets.each do |p|
        xml << self.template(p)
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

    # Rails-portlet Java class
    def portlet_filter_class
      'com.celamanzi.liferay.portlets.rails286.Rails286PortletRenderFilter'
    end

    protected

    def header
      xml =  '<?xml version="1.0" encoding="UTF-8"?>'
      xml << "\n"
      xml << '<portlet-app xmlns="http://java.sun.com/xml/ns/portlet/portlet-app_2_0.xsd"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xsi:schemaLocation="http://java.sun.com/xml/ns/portlet/portlet-app_2_0.xsd http://java.sun.com/xml/ns/portlet/portlet-app_2_0.xsd">'
      xml << "\n\n"
      return xml
    end

    def footer
      '</portlet-app>' + "\n"
    end

    # portlet.xml template.
    def template(portlet)
      xml =  "  <!-- %s -->\n" % portlet[:title]
      xml << "  <portlet>\n"
      xml << "    <portlet-name>%s</portlet-name>\n" % portlet[:name]
      xml << "    <portlet-class>%s</portlet-class>\n" % self.portlet_class
      xml << "    <supports>\n"
      xml << "      <mime-type>text/html</mime-type>\n"
      xml << "      <portlet-mode>view</portlet-mode>\n"
      ### edit mode
      xml << "      <portlet-mode>edit</portlet-mode>\n" if portlet[:edit]==true
      xml << "    </supports>\n"
      xml << "    <portlet-info>\n"
      xml << "      <title>%s</title>\n" % portlet[:title]
      xml << "    </portlet-info>\n"
      xml << "  </portlet>\n"
      xml << ""
      xml << "  <filter>\n"
      xml << "    <filter-name>%s_filter</filter-name>\n" % portlet[:name]
      xml << "    <filter-class>%s</filter-class>\n" % self.portlet_filter_class
      xml << "    <lifecycle>RENDER_PHASE</lifecycle>\n"
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
      xml << "  </filter>\n"
      xml << ""
      xml << "  <filter-mapping>\n"
      xml << "    <filter-name>%s_filter</filter-name>\n" % portlet[:name]
      xml << "    <portlet-name>%s</portlet-name>\n" % portlet[:name]
      xml << "  </filter-mapping>\n"
      xml << "\n"
    end

  end # static methods
  end
end