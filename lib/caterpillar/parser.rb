# encoding: utf-8
#--
# (c) Copyright 2008 Mikael Lammentausta
# See the file MIT-LICENSE included with the distribution for
# software license details.
#++

module Caterpillar
  # Portlet configuration and route parser.
  class Parser

#     include ActionController::Assertions::RoutingAssertions

    def initialize(config)
      @config = config
      @routes = config.routes
    end

    # Updates the portlets hash from the routes and configuration options.
    # Changes the path variables to a format supported by the Rails-portlet.
    def portlets(routes=@routes)
      raise 'No configuration' unless @config
      portlets = []

      @config.instances.flatten.each do |portlet|

        ### route to path
        if portlet[:path]
          # take user-given path & do not parse routes
          path = portlet[:path]
          #
          # parse the requirements - controller & action
          # ( this is too difficult -- no navigation for user-given paths )
          #
#           begin
#             #recognized_request_for(path)
#             #builder = ActionController::Routing::RouteBuilder.new
#             #r = ActionController::Routing::Routes.recognize_path(path, { :method => :get })
#             #puts r.inspect
#             #req_path = builder.segments_for_route_path(r)
#             #STDERR.puts req_path.inspect
#           rescue
#             STDERR.puts $!.message
#           end

          portlet.update( :reqs => {} )
          portlet.update( :vars => [] )

        else # parse path from routes
          begin
            _r = routes.select{
              |route| route[:name]==portlet[:name].to_sym
            }
            path = _r.first[:path] # take only the first segments
            raise if path.nil?
          rescue
            $stderr.puts ' !! no route for %s' % portlet[:name]
            next
          end
                                      
          # getting de default values from wildcards (:controller, :action, :other)
          portlet.update(:defaults => _r.first[:defaults])
          
          ### requirements - controller & action
          portlet.update( :reqs => _r.first[:reqs] )

          ### variables
          # take just the ones that are required in the path!
          vars = []
          _r.first[:vars].each do |var|
            # variables that are not defined in reqs are required to be inserted by the rails-portlet
            vars << var unless _r.first[:reqs][var]
          end
          portlet.update( :vars => vars )

          # delete the route from routes
	  if routes
            _r.each do |r|
              routes.delete(r)
            end
	  end
        end
        portlet.update( :path => path )

        ### javascripts
        # append portlet's javascripts to global javascripts
        javascripts = (portlet[:javascripts].nil? ?
          @config.javascripts : @config.javascripts + portlet[:javascripts].to_a)
        portlet.update( :javascripts => javascripts.flatten )

        portlets << portlet
      end

      # leftover named routes
      if @config.include_all_named_routes==true
        portlets << routes
      end

      # sanity check
      portlets.flatten!
      portlets.compact!
      portlets.each do |portlet|
        ### hostname
        portlet[:host] ||= @config.host

        ### servlet
        portlet[:servlet] ||= @config.servlet

        ### category
        portlet[:category] ||= @config.category

        ### title
        _title = portlet[:title] || portlet[:name].to_s.gsub('_',' ').capitalize
        # strip illegal characters
        title = _title.gsub(/ä/,'a').gsub(/ö/,'o').gsub(/Ä/,'A').gsub(/Ö/,'O')
        portlet.update( :title => title )

        portlet[:edit_mode] ||= nil
        portlet[:instanceable] ||= false

        ### unless defined, use default javascripts
        portlet[:javascripts] ||= @config.javascripts

        # fix path variables to be replaced by rails-portlet at runtime
        path = portlet[:path]
        path.gsub!(/:uid/,'%UID%')
        path.gsub!(/:gid/,'%GID%')
        # TODO: notify user of unsupported variables
        portlet.update( :path => path )
      end

      return portlets
    end

  end
end
