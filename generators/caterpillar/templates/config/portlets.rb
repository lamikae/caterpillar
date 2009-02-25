Caterpillar::Config.new do |portlet|

  # The portlet container.
  # By default only portlet.xml is created.
  # Currently only Liferay is supported. You may optionally define the version.
  portlet.container = Liferay
  # portlet.container.version = '5.1.1'

  # If you want to install the Rails-portlet JAR into the container, the container
  # WEB-INF will be used.
  #
  # Since liferay-display-ext.xml does not exist, all portlets are categorized in
  # liferay-display.xml. Caterpillar parses this file and appends Rails portlets.
  #
  # No changes are made to any of the files in this directory while making XML,
  # only the deploy and install tasks make any changes.
  portlet.container.root = '/usr/local/liferay/'

  # The hostname and port.
  # By default the values are taken from the request.
  # portlet.host

  # If the Rails is running inside a servlet container such as Tomcat,
  # you can define the servlet here.
  # By default the servlet is the name of the Rails app.
  # Remember to update this if you override Warbler's default.
  # portlet.servlet

  # Portlet category. This is only available for Liferay.
  # By default this is the same as the servlet.
  # portlet.category = 'Zcore'

  # Portlet instances.
  #
  # Each named route is mapped to a portlet.
  #
  # All keys except for 'name' are obligatory. If the name does not map to a route,
  # you have to define the route here.
  # You may override the host, servlet and category here.
  # Most likely you will want to let ActionController::Routing to set the route.
  #
  # Available keys are:
  #  - :name        -- named route
  #  - :category    -- portlet category (Liferay only)
  #  - :title       -- the title in portlet container's category (Liferay only)
  #  - :javascripts -- portlet-specific javascripts that are included at
  #                    the head of master HTML, such as body onload functions (Liferay only)
  #  - :host        -- hostname:port of the deployment server
  #  - :servlet     -- by default, the name of the Rails app (= name of the WAR package)
  #  - :path        -- unless you're using named routes, you can define the path here

  # Rails-portlet testing application:
  portlet.instances << {
    :name     => 'test',
    :title    => 'Rails-portlet testing application',
    :category => 'Caterpillar',
    :path     => '/RailsTestBench'
  }

  # this will include all named routes without further configuration
  portlet.include_all_named_routes = true

end
