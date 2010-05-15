# encoding: utf-8


#--
# (c) Copyright 2008,2009 Mikael Lammentausta
#
# See the file MIT-LICENSE included with the distribution for
# software license details.
#++

module Caterpillar # :nodoc:

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

    # server type:
    #  - 'Tomcat'
    #  - 'JBoss/Tomcat'
    attr_accessor :server

    # the name of the JBoss server directory
    attr_accessor :server_dir
    
    # For setting @deploy dir from the config file.
    # The "get" method is deploy_dir().
    attr_writer   :deploy_dir

    # Liferay version is given as a String, eg. '5.2.2'.
    # Defaults to +Lportal::Schema.version+.
    def initialize(version=nil)
      @version    = version
      @root       = '/usr/local/liferay-portal-5.2.3/tomcat-6.0.18' # as described in setup guide, when unpacked to /usr/local
      @server     = 'Tomcat'
      @deploy_dir = nil
    end

    # The name of the portal. Used in STDOUT messages.
    def name
      'Liferay'
    end

    # The directory where to deploy.
    # By default, it is based on the servlet container name and
    # the confured location of its root.
    # It can also be defined from the configuration file:
    # 	portlet.container.deploy_dir = '/opt/myDeployDir'
    def deploy_dir
      return @deploy_dir unless @deploy_dir.nil?

      raise 'Configure container root folder' unless self.root
      case @server

      when 'Tomcat'
        root_dir = 'ROOT'
        @deploy_dir = File.join(self.root,'webapps')

      when 'JBoss/Tomcat'
        # detect server name if not configured
        @server_dir ||= Dir.new(
            File.join(self.root,'server')).entries.first
        @deploy_dir = File.join(self.root,'server',@server_dir,'deploy')

      end

      unless File.exists?(@deploy_dir)
        raise 'Portal deployment directory does not exist: %s' % @deploy_dir
      end

      return @deploy_dir
    end

    # The location of Liferay's WEB-INF folder for XML analyzation.
    # This is relative to installation directory (self.root)
    def WEB_INF
      raise 'Configure container root folder' unless self.root
      case @server

      when 'Tomcat'
        root_dir = 'ROOT'
        return web_inf_dir(root_dir)

      when 'JBoss/Tomcat'
        # detect lportal dir (ROOT.war or lportal.war)
        root_dir =
          if File.exists?(File.join(self.deploy_dir,'ROOT.war'))
            'ROOT.war'
          elsif File.exists?(File.join(self.deploy_dir,'lportal.war'))
            'lportal.war'
          end
        unless root_dir
          STDERR.puts 'There seems to be a problem detecting the proper install paths.'
          STDERR.puts 'Please file a bug on Caterpillar.'
          raise 'Portal root directory not found at %s' % self.deploy_dir
        end
                
        return web_inf_dir(root_dir)

      end
    end
    
    # The rule by which the WEB-INF is constructed regardless of the server.
    def web_inf_dir(root_dir)
      # The @deploy_dir variable does not need checking,
      # as the method deploy_dir() does that.
      #if deploy_dir_defined?
                                  
      #self.deploy_dir(),    
      # Xml files need to be in WEB-INF and not, for example, /opt/liferay/deploy
      return File.join(File.join(self.root,'webapps'), root_dir,'WEB-INF')
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

    # DTD version detection based on self.version
    def dtd_version(type)
      #case type
      #when 'liferay-portlet-app'
      #when 'display'
      self.version[/.../] + '.0'
    end

    # liferay-portlet-ext definition
    #
    # http://www.liferay.com/web/guest/community/wiki/-/wiki/Main/Liferay-portlet.xml
    #
    # The content of element type "portlet" must match "(portlet-name,icon?,virtual-path?,struts-path?,configuration-path?,configuration-action-class?,indexer-class?,open-search-class?,scheduler-class?,portlet-url-class?,friendly-url-mapper-class?,url-encoder-class?,portlet-data-handler-class?,portlet-layout-listener-class?,poller-processor-class?,pop-message-listener-class?,social-activity-interpreter-class?,social-request-interpreter-class?,webdav-storage-token?,webdav-storage-class?,control-panel-entry-category?,control-panel-entry-weight?,control-panel-entry-class?,preferences-company-wide?,preferences-unique-per-layout?,preferences-owned-by-group?,use-default-template?,show-portlet-access-denied?,show-portlet-inactive?,action-url-redirect?,restore-current-view?,maximize-edit?,maximize-help?,pop-up-print?,layout-cacheable?,instanceable?,scopeable?,user-principal-strategy?,private-request-attributes?,private-session-attributes?,render-weight?,ajaxable?,header-portal-css*,header-portlet-css*,header-portal-javascript*,header-portlet-javascript*,footer-portal-css*,footer-portlet-css*,footer-portal-javascript*,footer-portlet-javascript*,css-class-wrapper?,facebook-integration?,add-default-resource?,system?,active?,include?)".
    def portletapp_template(portlet)
      xml =  "  <portlet>\n"
      xml << "    <portlet-name>%s</portlet-name>\n" % portlet[:name]
      xml << "    <icon>%s</icon>\n" % [
          portlet[:host], portlet[:servlet], 'favicon.png' # .ico does not work on Firefox 3.0
        ].join('/').gsub(/([^:])\/\//,'\1/')

      # define the control panel category for Liferay 5.2 and newer -
      #
      # Note that when the control panel settings are defined,
      # the portlet cannot be instanceable.
      unless @version[/5.1/]
        xml << "    <control-panel-entry-category>#{portlet[:category]}</control-panel-entry-category>\n"
        xml << "    <control-panel-entry-weight>420.0</control-panel-entry-weight>\n"
        #xml << "    <control-panel-entry-class></control-panel-entry-class>\n"
      end

      # Set the use-default-template value to true if the portlet uses the default template to decorate and wrap content. Setting this to false allows the developer to own and maintain the portlet's entire outputted content. The default value is true.
      #
      # The most common use of this is if you want the portlet to look different from the other portlets or if you want the portlet to not have borders around the outputted content.
      #
      # RD: This is a nice option except that if you set it, then you loose all border functionality including drag, drop, min,max,edit,conf,close These should be controlled by a separate property.
      xml << "    <use-default-template>true</use-default-template>\n"

      # can there be several portlet instances on the same page?
      xml << "    <instanceable>#{portlet[:instanceable]}</instanceable>\n"

      # The default value of ajaxable is true. If set to false, then this portlet can never be displayed via Ajax.
      xml << "    <ajaxable>true</ajaxable>\n"

      # include javascripts?
      js_tag = (@version[/5.1/] ? 'header' : 'footer') + '-portal-javascript'
      portlet[:javascripts].each do |js|
        xml << "    <#{js_tag}>"
        xml << "/#{portlet[:servlet]}/javascripts/#{js}"
        xml << "</#{js_tag}>\n"
      end

      # If the add-default-resource value is set to true, the default portlet resources and permissions are added to the page. The user can then view the portlet.
      xml << "    <add-default-resource>true</add-default-resource>\n"
      xml << "    <system>false</system>\n"
      xml << "    <active>true</active>\n"
      xml << "    <include>true</include>\n"

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
      %w{
        cyrususer
        cyrusvirtual
        documentlibrary_fsentry
        documentlibrary_binval
        documentlibrary_node
        documentlibrary_prop
        documentlibrary_refs
        expandocolumn
        expandorow
        expandotable
        expandovalue
        image
        chat_entry
        chat_status
        journalcontentsearch
        mbban
        membershiprequest
        orglabor
        passwordpolicyrel
        passwordpolicy
        passwordtracker
        pluginsetting
        quartz_blob_triggers
        quartz_calendars
        quartz_cron_triggers
        quartz_fired_triggers
        quartz_job_details
        quartz_job_listeners
        quartz_locks
        quartz_paused_trigger_grps
        quartz_scheduler_state
        quartz_simple_triggers
        quartz_trigger_listeners
        quartz_triggers
        ratingsentry
        ratingsstats
        region
        scframeworkversion
        scframeworkversi_scproductvers
        schema_migrations
        sclicenses_scproductentries
        sclicense
        scproductentry
        scproductscreenshot
        scproductversion
        servicecomponent
        sessions
        shoppingcart
        shoppingcategory
        shoppingcoupon
        shoppingitemfield
        shoppingitemprice
        shoppingitem
        shoppingorderitem
        shoppingorder
        subscription
        tasksproposal
        tasksreview
        webdavprops
        website
      }
    end

  end
end
