#--
# (c) Copyright 2008 Mikael Lammentausta
# See the file LICENSES.txt included with the distribution for
# software license details.
#++

module Caterpillar
  # Portlet configuration and route parser.
  class Parser

    def initialize(config)
      @config = config
      @routes = config.routes
    end

    # Updates the portlets hash from the routes and configuration options.
    # Changes the path variables to a format supported by the Rails-portlet.
    def portlets(routes=@routes)
      raise 'No configuration' unless @config
      raise 'No routes provided' unless routes
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
          # builder = ActionController::Routing::RouteBuilder.new
          # req_path = builder.segments_for_route_path(path)
          # r = ActionController::Routing::Routes.recognize_path(req_path, { :method => :get })
          # puts r.inspect

          portlet.update( :reqs => {} )
          portlet.update( :vars => [] )

        else
          begin
            _r = routes.select{
              |route| route[:name]==portlet[:name].to_sym
            }
            path = _r.first[:path] # take only the first segments
            raise if path.nil?
          rescue
            STDERR.puts ' !! no route for %s' % portlet[:name]
            next
          end

          ### requirements - controller & action
          portlet.update( :reqs => _r.first[:reqs] )

          ### variables
          portlet.update( :vars => _r.first[:vars] )

          # delete the route from routes
          _r.each do |r|
            routes.delete(r)
          end
        end
        # fix path variables to be replaced by rails-portlet at runtime
        path.gsub!(/:uid/,'%UID%')
        path.gsub!(/:gid/,'%GID%')
        # TODO: notify user of unsupported variables
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
        portlets.flatten!
      end

      # sanity check
      portlets.each do |portlet|
        ### hostname
        portlet.update( :host => @config.host ) unless portlet[:host]

        ### servlet
        portlet.update( :servlet => @config.servlet ) unless portlet[:servlet]

        ### category
        portlet.update( :category => @config.category ) unless portlet[:category]

        ### title
        _title = portlet[:title] || portlet[:name].to_s.gsub('_',' ').capitalize
        # strip illegal characters
        title = _title.gsub(/ä/,'a').gsub(/ö/,'o').gsub(/Ä/,'A').gsub(/Ö/,'O')
        portlet.update( :title => title )

        ### javascripts
        portlet.update( :javascripts => @config.javascripts ) unless portlet[:javascripts]
      end

      return portlets
    end

  end
end
