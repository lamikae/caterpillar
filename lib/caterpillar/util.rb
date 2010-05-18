# encoding: utf-8
#--
# (c) Copyright 2008,2009,2010 Mikael Lammentausta
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
      #STDERR.puts 'Caterpillar configuration file could not be found' unless File.exists?(cf)

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

    # Collects Rails' named routes
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

        # Ruby 1.9
        if route.class == Symbol
          name = route
          _route = ActionController::Routing::Routes.named_routes.routes[route]
        # Ruby 1.8
        elsif route.class == Array
          name = route[0]
          _route = route[1] # 'ActionController::Routing::Route'
        end

        # segments; the path
        segs = _route.segments.inject("") { |str,s| str << s.to_s }
        segs.chop! if segs.length > 1
        # controller and action
        reqs = _route.requirements
        # extra variables
        keys = _route.significant_keys
        vars = keys - [:action, :controller]

        {:name => name, :path => segs, :reqs => reqs, :vars => vars}
      end
    end

    # Reorganizes the portlets hash by category.
    #
    #  {'Category 1' => [portlets], 'Category 2' => [portlets]}
    def categorize(portlets)
      ret = {}

      # organize into main categories
      categories = portlets.collect{|p| p[:category]}
      categories << portlets.collect{|p| p[:categories].first if p[:categories]}
      categories.flatten!.uniq!

      categories.each do |category|
        next if category.nil? # skip nil categories

        # does this category have subcategories?
        # skip them. TODO: parse internal categories
        if (portlets.map{|p| (
          !p[:categories].nil? && \
          p[:categories].first==category)} & [true] ).any?
          STDERR.puts '%s has subcategories, skipping' % category.inspect
          next
        end

        # select the portlets in this category
        _portlets = portlets.select do |p|
          p[:category]==category or (!p[:categories].nil? and p[:categories].include?(category))
        end

        ret.update(category => _portlets)
      end

      return ret
    end

    end # static
  end
end
