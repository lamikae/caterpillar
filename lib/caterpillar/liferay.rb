# encoding: utf-8
#--
# (c) Copyright 2008-2010 Mikael Lammentausta
#
# See the file MIT-LICENSE included with the distribution for
# software license details.
#++

require "rexml/document"

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
      @version    = version || '5.2.3'
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
      return @deploy_dir if @deploy_dir # user configuration

      case @server
      when 'Tomcat'
        raise 'Configure container root directory' unless @root
        return File.join(@root,'webapps')

      when 'JBoss/Tomcat'
        raise "Please configure deploy directory for JBoss."

      end
    end

    # The location of Liferay's WEB-INF folder,
    # relative to installation directory (@root).
    # This is where the XML files are housed.
    def WEB_INF
      raise 'Configure container root directory' unless @root
      case @server

      when 'Tomcat'
        return File.join(@root, %w{webapps ROOT WEB-INF})

      when 'JBoss/Tomcat'
        # user should configure server_dir !!
        unless @server_dir
          raise 'Please configure server_dir for JBoss/Tomcat'
        end
        return File.join(@root, @server_dir, 'WEB-INF')

      end
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
      doc = REXML::Document.new
      doc << REXML::XMLDecl.new('1.0', 'utf-8') 
      doc << REXML::DocType.new('liferay-portlet-app',
        'PUBLIC  '+\
        '"-//Liferay//DTD Portlet Application %s//EN"  ' % (self.dtd_version) +\
        '"http://www.liferay.com/dtd/liferay-portlet-app_%s.dtd"' % self.dtd_version.gsub('.','_')
        )
      app = REXML::Element.new('liferay-portlet-app', doc)

      portlets.each do |portlet|
        # <portlet>
        app.elements << self.portlet_element(portlet)
        # <role-mapper>s
        roles.each {|role| app.elements << role}
      end

      xml = ''
      #doc.write(xml, -1) # no indentation, tag and text should be on same line
      doc.write(xml, 4) # without identation is very dificult to reconfigure those files in production
      return xml.gsub('\'', '"') # fix rexml attribute single quotes to double quotes
    end

    # liferay-display XML
    def display_xml(portlets)
      liferay_display_file = File.join(self.WEB_INF,'liferay-display.xml')
      
      doc = REXML::Document.new File.new(liferay_display_file)
      display = doc.root
                    
      # include portlets
      Util.categorize(portlets).each_pair do |category_name, portlets|
        category = nil
        display.each_element {|e| if e.attributes['name'] == category_name.to_s then category = e; break end}
        
        unless category
          category = REXML::Element.new('category', display)
          category.attributes['name'] = category_name.to_s
        end
        
        portlets.each do |portlet|
          if category.has_elements?
            # unless he holds does not add again              
            category.each_element do |e|
              unless e.attributes['id'] == portlet[:name]
                category.add_element 'portlet', {'id' => portlet[:name]}
                break
              end
            end
          else
            category.add_element 'portlet', {'id' => portlet[:name]}
          end
        end                         
        
      end

      xml = ''
      #doc.write(xml, -1) # no indentation, tag and text should be on same line
      doc.write(xml, 4) # without identation is very dificult to reconfigure those files in production
      return xml.gsub('\'', '"') # fix rexml attribute single quotes to double quotes
    end

    protected

    # <portlet> element for liferay-portlet-ext.xml
    #
    # http://www.liferay.com/web/guest/community/wiki/-/wiki/Main/Liferay-portlet.xml
    #
    def portlet_element(portlet)
      element = REXML::Element.new('portlet')

      REXML::Element.new('portlet-name', element).text = portlet[:name]
      REXML::Element.new('icon', element).text = [
          portlet[:host], portlet[:servlet], 'favicon.png' # .ico does not work on Firefox 3.0
        ].join('/').gsub(/([^:])\/\//,'\1/')

      # define the control panel category for Liferay 5.2 and newer -
      #
      # Note that when the control panel settings are defined,
      # the portlet cannot be instanceable.
      unless @version[/5.1/]
        REXML::Element.new('control-panel-entry-category', element).text = portlet[:category]
        REXML::Element.new('control-panel-entry-weight', element).text = '420.0'
      end

      # Set the use-default-template value to true if the portlet uses the default template to decorate and wrap content. Setting this to false allows the developer to own and maintain the portlet's entire outputted content. The default value is true.
      #
      # The most common use of this is if you want the portlet to look different from the other portlets or if you want the portlet to not have borders around the outputted content.
      #
      # RD: This is a nice option except that if you set it, then you loose all border functionality including drag, drop, min,max,edit,conf,close These should be controlled by a separate property.
      REXML::Element.new('use-default-template', element).text = 'true'

      # can there be several portlet instances on the same page?
      REXML::Element.new('instanceable', element).text = portlet[:instanceable].to_s

      # The default value of ajaxable is true. If set to false, then this portlet can never be displayed via Ajax.
      REXML::Element.new('ajaxable', element).text = 'true'

      # include javascripts?
      js_tag = (@version[/5.1/] ? 'header' : 'footer') + '-portal-javascript'
      portlet[:javascripts].each do |js|
        REXML::Element.new(js_tag, element).text = "/#{portlet[:servlet]}/javascripts/#{js}"
      end

      # If the add-default-resource value is set to true, the default portlet resources and permissions are added to the page. The user can then view the portlet.
      REXML::Element.new('add-default-resource', element).text = 'true'
      REXML::Element.new('system', element).text = 'false'
      REXML::Element.new('active', element).text = 'true'
      REXML::Element.new('include', element).text = 'true'

      return element
    end

    # DTD version based on self.version
    def dtd_version
      self.version[/.../] + '.0'
    end

    private

    # XML role-mapper.
    def roles
      elements = []
      # name => link
      {
        'administrator' => 'Administrator',
        'guest' => 'Guest',
        'power-user' => 'Power User',
        'user' => 'User'
      }.each_pair do |name,link|
        mapper = REXML::Element.new('role-mapper')
        REXML::Element.new('role-name', mapper).text = name
        REXML::Element.new('role-link', mapper).text = link
        elements << mapper
      end
      return elements
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
