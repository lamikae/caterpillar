#--
# (c) Copyright 2008 Mikael Lammentausta
# See the file LICENSES.txt included with the distribution for
# software license details.
#++

module Caterpillar
  # Creates liferay-portlet XML and liferay-display XML.
  # The latter optionally combines your production portlet display configuration.
  class Liferay

    # Liferay version
    attr_accessor :version

    # the installation directory
    attr_accessor :root

    def initialize(version='5.1.1')
      @version = version
    end

    # The location of Liferay's WEB-INF folder for XML analyzation.
    # This is relative to installation directory (self.root)
    def WEB_INF
      raise 'Configure container root folder' unless self.root
      File.join(self.root,'webapps','ROOT','WEB-INF')
    end

    def analyze(type)
      require 'hpricot'
      return nil unless type==:native

      portlets = []

      f=File.open(self.WEB_INF+'/portlet-custom.xml','r')
      portlet_xml = Hpricot.XML(f.read)
      f.close

      f=File.open(self.WEB_INF+'/liferay-display.xml','r')
      display_xml = Hpricot.XML(f.read)
      f.close

      (portlet_xml/'portlet').each do |portlet|
        _p = {
          :name  => (portlet/'portlet-name').innerHTML,
          :title => (portlet/'display-name').innerHTML
        }

        # horribly ineffective
        display_xml.search("//category").each do |c|
          _p.update(:category => c['name'] ) if (c/"//portlet[@id='#{_p[:name]}']").any?
        end

        portlets << _p
      end
      return portlets
    end

    # liferay-portlet XML
    def portletapp_xml(portlets)
      doctype = 'liferay-portlet-app'
      xml = self.xml_header(doctype)
      portlets.each do |p|
        xml << self.portletapp_template(p)
      end
      xml << self.portlet_xml_footer(doctype)
      return xml
    end

    # liferay-display XML
    def display_xml(portlets)
      xml = self.xml_header('display')

      categories = []
      Util.categorize(portlets).each_pair do |category,portlets|
        categories << category
        xml << self.display_template(category,portlets)
      end

      # include other native Liferay categories
      if self.WEB_INF
        require 'hpricot'

        filename = self.WEB_INF+'/liferay-display.xml'
        f=File.open(filename,'r')
        doc = Hpricot.XML(f.read)
        f.close
        (doc/:category).each do |el|
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
        '5.1.0'
      when 'display'
        '5.1.0'
      end
    end

    def portletapp_template(portlet)
      xml =  "  <portlet>\n"
      xml << "    <portlet-name>%s</portlet-name>\n" % portlet[:name]
      xml << "    <icon>/%s/images/icon.png</icon>\n" % portlet[:servlet]
      # can there be several portlet instances on the same page?
      xml << "    <instanceable>true</instanceable>\n"
      # include javascripts?
      portlet[:javascripts].each do |js|
        xml << "    <header-portal-javascript>"
        xml << "/%s/javascripts/%s" % [portlet[:servlet],js]
        xml << "</header-portal-javascript>\n"
      end
      xml << "  </portlet>\n\n"
    end

    def display_template(category,portlets)
      xml = '  <category name="%s">' % category +"\n"

      portlets.each do |p|
        xml << '    <portlet id="%s" />' % p[:name]
        xml << "\n"
      end
      xml << "  </category>\n\n"

      return xml
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
        "mbmessageflag",
        "mbstatsuser",
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
        "release_",
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
        "socialactivity",
        "socialrelation",
        "subscription",
        "tasksproposal",
        "tasksreview",
        "webdavprops",
        "website"
      ]
    end

  end
end
