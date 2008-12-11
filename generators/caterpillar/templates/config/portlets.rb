Caterpillar::Config.new do |portlet|

  # The portlet container.
  # By default only portlet.xml is created.
  # Currently only Liferay is supported. You may optionally define the version.
  portlet.container = Liferay
  # portlet.container.version = '5.1.1'

  # Dince liferay-display-ext.xml does not exist, all portlets are categorized in
  # liferay-display.xml. If you intend to keep other portlets still intact,
  # you need to specify the location of WEB-INF.
  # No changes are made to any of the files in this directory.
  portlet.container.WEB_INF = '/usr/local/liferay/webapps/ROOT/WEB-INF/'

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
  #  - :javascripts -- portlet-specific javascripts that are not in the HTML head section (Liferay only)
  #  - :host
  #  - :servlet
  #  - :path        -- unless you're using named routes, you can define the path here

  # example:
  #   portlet.instances << {
  #     :name     => 'rails286_test',
  #     :title    => 'Rails-portlet testing application',
  #     :category => 'Testing',
  #     :servlet  => 'RailsTestBench',
  #     :path     => '/'
  #   }

  # this will include all named routes without further configuration
  portlet.include_all_named_routes = true

end
