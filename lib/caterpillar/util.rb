# encoding: utf-8
#--
# (c) Copyright 2008,2009,2010 Mikael Lammentausta
# See the file MIT-LICENSE included with the distribution for
# software license details.
#++

module Caterpillar
  # Common utility methods
  class Util
    class << self

    # Reads and evaluates the configuration.
    # If parameter is not given, read from default location (RAILS_ROOT/config/portlets.rb)
    def eval_configuration(conf_file=nil)
      return Config.new if not (conf_file or defined?(RAILS_ROOT))
      # else . . .
      conf_file ||= File.join([RAILS_ROOT,Caterpillar::Config::FILE])
      if File.exists?(conf_file)
        #$stdout.puts "Reading configuration from #{conf_file}" 
        config = eval(File.open(conf_file) {|f| f.read})
      end
      unless config.kind_of? Config
        $stderr.puts "Configuration was not parsed properly"
        config = Config.new
      end
      return config
    end

    # Collects Rails' named routes
    def parse_routes(config)
      require 'action_controller'
      require File.join(CATERPILLAR_LIBS, '..','portlet_test_bench', 'routing')
      ActionController::Routing::RouteSet::Mapper.send :include, Caterpillar::Routing::MapperExtensions

      routes = []
      config.instances.each do |portlet|

        # clear old routes from memory and reload ActionController
        ActionController::Routing::Routes.clear!

        # prefer portlet rails_root
        if portlet[:rails_root]
          rails_root = portlet[:rails_root]
        elsif config.rails_root
          rails_root = config.rails_root
        else
          next
        end
        # load routes
        f = File.open(
          File.join(
            rails_root,'config','routes.rb'
            ))
        eval(f.read())
        f.close()

        routes <<
          ActionController::Routing::Routes.named_routes.collect do |route| 
            # Ruby 1.9
            if route.class == Symbol
              name = route
              _route = ActionController::Routing::Routes.named_routes.routes[route]
              defaults = {} #TODO: Get default values in ruby 1.9
            # Ruby 1.8
            elsif route.class == Array
              name = route[0]
              _route = route[1] # 'ActionController::Routing::Route'
              defaults = route[-1].defaults
            end

            # segments; the path
            segs = _route.segments.inject("") { |str,s| str << s.to_s }
            segs.chop! if segs.length > 1
            # controller and action
            reqs = _route.requirements
            # extra variables
            keys = _route.significant_keys
            vars = keys - [:action, :controller]

            {:name => name, :path => segs, :reqs => reqs, :vars => vars, :defaults => defaults}
          end
      end
      return routes.flatten
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

      # add portlets without category
      uncategorized = portlets.select {|p| p[:category].nil?}
      if uncategorized.any?
        ret.update('undefined' => uncategorized)
      end

      return ret
    end

    def xml_to_s(doc)
      # Serializes the REXML::Document to String.
      # It has to pass Ruby unit test validation and Liferay runtime validation.
      # The XML requires strict ordering of the child nodes,
      # and also tags and values have to be on a single line.
      require 'rexml/formatters/pretty'
      str = String.new
      fmt = REXML::Formatters::Pretty.new(4)
      fmt.compact = true
      fmt.write(doc,str)
      return str.gsub('\'', '"') # fix rexml attribute single quotes to double quotes
    end

    end # static
  end
end
