#--
# (c) Copyright 2008,2009 Mikael Lammentausta
#
# See the file MIT-LICENSE included with the distribution for
# software license details.
#++

module Caterpillar
  # Creates liferay-portlet XML and liferay-display XML.
  # The latter optionally combines your production portlet display configuration.
  #
  # See http://www.liferay.com/web/guest/community/wiki/-/wiki/Main/Liferay-portlet.xml
  #
  # Supported portlet.xml tags:
  # (*) stands for non-configurable
  #
  #     <portlet-name>
  #     <icon> (*)
  #     <instanceable> (*; always true)
  #
  # 5.1.x -specific:
  #     <header-portal-javascript>
  #
  # 5.2.0 -specific:
  #     <footer-portal-javascript>
  #     <control-panel-entry-category>
  #     <control-panel-entry-weight> (*; always 99.0)
  #
  # TODO:
  #     <footer-portlet-javascript>
  #     <header-portlet-css>
  #     <use-default-template>
  #     <private-request-attributes>
  #     <private-session-attributes>
  #     <render-weight>
  #     <restore-current-view>
  #
  class Liferay

    # Liferay version
    attr_accessor :version

    # the installation directory
    attr_accessor :root

    # Liferay version is given as a String, eg. '5.2.2'.
    # Defaults to +Lportal::Schema.version+.
    def initialize(version=nil)
      @version = version
      @root    = '/usr/local/liferay'
    end

    # The name of the portal. Used in STDOUT messages.
    def name
      'Liferay'
    end

    # The location of Liferay's WEB-INF folder for XML analyzation.
    # This is relative to installation directory (self.root)
    def WEB_INF
      raise 'Configure container root folder' unless self.root
      File.join(self.root,'webapps','ROOT','WEB-INF')
    end

    # Reads Liferay portlet descriptor XML files and parses them with Hpricot.
    def analyze(type=:native)
      require 'hpricot'
      return nil unless type==:native

      portlets = []

      f=File.open(self.WEB_INF+'/portlet-custom.xml','r')
      custom_xml = Hpricot.XML(f.read)
      f.close

      f=File.open(self.WEB_INF+'/liferay-portlet.xml','r')
      portlet_xml = Hpricot.XML(f.read)
      f.close

      f=File.open(self.WEB_INF+'/liferay-display.xml','r')
      display_xml = Hpricot.XML(f.read)
      f.close

      (custom_xml/'portlet').each do |portlet|
        _p = {
          :id    => (portlet/'portlet-name').innerHTML,
          :title => (portlet/'display-name').innerHTML
        }

        # search portlet metadata
        portlet_xml.search("//portlet-name").each do |p|
          if p.innerHTML==_p[:id]
            _p.update(:name => (p/"../struts-path").text)

            # is the portlet instanceable?
            # it seems that if undefined, the default is "false"
            _p.update(:instanceable => (p/"../instanceable").text=='true')
          end
        end

        # search the category - horribly ineffective.
        # the categories is an Array where each raising index is a new subcategory
        display_xml.search("display/category").each do |c|
          if (c/"//portlet[@id='#{_p[:id]}']").any?
            # the portlet is in this category
            categories = [c['name']]

            # child categories
            c.search("category").each do |child|
              categories << child['name']
            end

            if categories.size > 1
              _p.update(:categories => categories)
            else
              _p.update(:category => categories.first)
            end
            # debug
            #puts _p.inspect
            #portlets << _p

          end
        end

        portlets << _p
      end
      return portlets
    end

    # liferay-portlet XML
    def portletapp_xml(portlets)
      doctype = 'liferay-portlet-app'
      xml = xml_header(doctype)
      portlets.each do |p|
        xml << portletapp_template(p)
      end
      xml << roles
      xml << portlet_xml_footer(doctype)
    end

    # liferay-display XML
    def display_xml(portlets)
      xml = self.xml_header('display')

      categories = []
      # process Rails portlets
      Util.categorize(portlets).each_pair do |category,portlets|
        categories << category
        xml << self.display_template(category,portlets)
      end

      # include other native Liferay portlets and categories
      if self.WEB_INF
        require 'hpricot'

        filename = self.WEB_INF+'/liferay-display.xml'
        f=File.open(filename,'r')
        doc = Hpricot.XML(f.read)
        f.close
        (doc/"display/category").each do |el|
          unless categories.include?(el.attributes['name'])
            xml << '  ' + el.to_original_html + "\n"
          end
        end
      end

      xml << self.portlet_xml_footer('display')
      return xml
    end

    protected

    # common XML header
    def xml_header(doctype)
      version = self.dtd_version(doctype)
      xml =  '<?xml version="1.0" encoding="UTF-8"?>'
      xml << "\n"
      xml << '<!DOCTYPE %s PUBLIC' % doctype
      case doctype

      when 'liferay-portlet-app'
        xml << '  "-//Liferay//DTD Portlet Application %s//EN"' % version
        xml << '  "http://www.liferay.com/dtd/%s_%s.dtd">' % [
        doctype, version.gsub('.','_') ]

      when 'display'
        xml << '  "-//Liferay//DTD Display %s//EN"' % version
        xml << '  "http://www.liferay.com/dtd/liferay-%s_%s.dtd">' % [
        doctype, version.gsub('.','_') ]

      end
      xml << "\n\n"
      xml << '<%s>' % doctype
      xml << "\n"
      return xml
    end

    # common XML footer
    def portlet_xml_footer(doctype)
      '</%s>' % doctype
    end

    # TODO: DTD version detection based on self.version
    def dtd_version(type)
      case type
      when 'liferay-portlet-app'
        if @version[/5.1/]
          '5.1.0'
        elsif @version[/5.2/]
          '5.2.0'
        else
          @version
        end
      when 'display'
        if @version[/5.1/]
          '5.1.0'
        elsif @version[/5.2/]
          '5.2.0'
        else
          @version
        end
      end
    end

    # the actual portlet definition
    def portletapp_template(portlet)
      xml =  "  <portlet>\n"
      xml << "    <portlet-name>%s</portlet-name>\n" % portlet[:name]
      xml << "    <icon>/%s/favicon.ico</icon>\n" % portlet[:servlet]
      # can there be several portlet instances on the same page?
      xml << "    <instanceable>false</instanceable>\n"
      # define the control panel category for 5.2 and newer -
      # Note that when the control panel settings are defined,
      # the portlet cannot be instanceable.
      unless @version[/5.1/]
        xml << "    <control-panel-entry-category>#{portlet[:category]}</control-panel-entry-category>\n"
        xml << "    <control-panel-entry-weight>1.0</control-panel-entry-weight>\n"
      end
      # include javascripts?
      js_tag = (@version[/5.1/] ? 'header' : 'footer') + '-portal-javascript'
      portlet[:javascripts].each do |js|
        xml << "    <#{js_tag}>"
        xml << "/#{portlet[:servlet]}/javascripts/#{js}"
        xml << "</#{js_tag}>\n"
      end
      xml << "  </portlet>\n\n"
    end

    def display_template(category,portlets)
      xml = '  <category name="%s">' % category +"\n"
      portlets.each do |p|
        xml << '    <portlet id="%s" />' % p[:name] + "\n"
      end
      xml << "  </category>\n\n"
    end

    private

    # XML role-mapper.
    # Has to be duplicated in -ext.xml
    def roles
      xml =  "  <role-mapper>\n"
      xml << "    <role-name>administrator</role-name>\n"
      xml << "    <role-link>Administrator</role-link>\n"
      xml << "  </role-mapper>\n"
      xml << "  <role-mapper>\n"
      xml << "    <role-name>guest</role-name>\n"
      xml << "    <role-link>Guest</role-link>\n"
      xml << "  </role-mapper>\n"
      xml << "  <role-mapper>\n"
      xml << "    <role-name>power-user</role-name>\n"
      xml << "    <role-link>Power User</role-link>\n"
      xml << "  </role-mapper>\n"
      xml << "  <role-mapper>\n"
      xml << "    <role-name>user</role-name>\n"
      xml << "    <role-link>User</role-link>\n"
      xml << "  </role-mapper>\n"
    end

    public

    # tables that are skipped when creating fixtures
    def skip_fixture_tables
      [
        "cyrususer","cyrusvirtual",
        "documentlibrary_fsentry","documentlibrary_binval","documentlibrary_node","documentlibrary_prop","documentlibrary_refs",
        "expandocolumn",
        "expandorow",
        "expandotable",
        "expandovalue",
        "image",
        "chat_entry",
        "chat_status",
        "journalcontentsearch",
        "mbban",
        "membershiprequest",
        "orglabor",
        "passwordpolicyrel",
        "passwordpolicy",
        "passwordtracker",
        "pluginsetting",
        "quartz_blob_triggers",
        "quartz_calendars",
        "quartz_cron_triggers",
        "quartz_fired_triggers",
        "quartz_job_details",
        "quartz_job_listeners",
        "quartz_locks",
        "quartz_paused_trigger_grps",
        "quartz_scheduler_state",
        "quartz_simple_triggers",
        "quartz_trigger_listeners",
        "quartz_triggers",
        "ratingsentry",
        "ratingsstats",
        "region",
        "scframeworkversion",
        "scframeworkversi_scproductvers",
        "schema_migrations",
        "sclicenses_scproductentries",
        "sclicense",
        "scproductentry",
        "scproductscreenshot",
        "scproductversion",
        "servicecomponent",
        "sessions",
        "shoppingcart",
        "shoppingcategory",
        "shoppingcoupon",
        "shoppingitemfield",
        "shoppingitemprice",
        "shoppingitem",
        "shoppingorderitem",
        "shoppingorder",
        "subscription",
        "tasksproposal",
        "tasksreview",
        "webdavprops",
        "website"
      ]
    end

  end
end
