#--
# (c) Copyright 2008 Mikael Lammentausta
# See the file LICENSES.txt included with the distribution for
# software license details.
#++

module Caterpillar
  # Common utility methods
  class Util
    class << self

    # Reads the configuration
    def eval_configuration(config=nil)
      cf = File.join([RAILS_ROOT,Caterpillar::Config::FILE])
      if config.nil? && File.exists?(cf)
        config = eval(File.open(cf) {|f| f.read})
      end
      config ||= Config.new
      unless config.kind_of? Config
        warn "Portlet config not provided by override in initializer or #{Config::FILE}; using defaults"
        config = Config.new
      end
      return config
    end

    # Collects Rails' routes and parses the config
    def parse_routes(config)
# taken from Rails' "routes" task
#         routes = ActionController::Routing::Routes.routes.collect do |route|
#           name = ActionController::Routing::Routes.named_routes.routes.index(route).to_s
#           verb = route.conditions[:method].to_s.upcase
#           segs = route.segments.inject("") { |str,s| str << s.to_s }
#           segs.chop! if segs.length > 1
#           reqs = route.requirements.empty? ? "" : route.requirements.inspect
#           {:name => name, :verb => verb, :segs => segs, :reqs => reqs}
#         end

      ActionController::Routing::Routes.named_routes.collect do |route|
        name = route[0]
        # segments; the path
        segs = route[1].segments.inject("") { |str,s| str << s.to_s }
        segs.chop! if segs.length > 1
        # controller and action
        reqs = route[1].requirements

        # extra variables
        keys = route[1].significant_keys
        vars = keys - [:action, :controller]

        {:name => name, :path => segs, :reqs => reqs, :vars => vars}
      end
    end

    # Reorganizes the portlets hash by category.
    #
    #  {'Category 1' => [portlets], 'Category 2' => [portlets]}
    def categorize(portlets)
      ret = {}
# STDERR.puts portlets.first.inspect

      # organize into categories
      categories = portlets.collect{|p| p[:category]}.uniq.each do |category|
        # select the portlets in this category
        _portlets = portlets.select{|p| p[:category]==category}
        ret.update(category => _portlets)
      end

# puts ret.inspect


#       {'Zcore' => [], 'Foo' => []}

      return ret
    end




    end # static
  end
end
