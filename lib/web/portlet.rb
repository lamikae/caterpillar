require 'rubygems'
require 'active_record'

module Web # :nodoc:
  class Portlet < ActiveRecord::Base

    # Various static properties of the portlet instance.
    def properties
      Web::PortletProperties.find_by_portletid self.portletid.to_s
    end

    @@caterpillar_portlets = nil

    def self.caterpillar_portlets
      return @@caterpillar_portlets if @@caterpillar_portlets

      config = Caterpillar::Util.eval_configuration
      config.routes = Caterpillar::Util.parse_routes(config)

      # transform objects
      portlets = []
      Caterpillar::Parser.new(config).portlets.each do |p|
        portlets << self.new(
          :portletid => p[:name].to_s
        )
      end

      @@caterpillar_portlets = portlets
    end

    def self.find_caterpillar_portlet(name)
      self.caterpillar_portlets.select{
        |p| p.name=='%s' % name }.first # find_by_name
    end

    # read-only
    def title
      p = Web::PortletProperties.find_by_portletid(self.portletid)
      p ? p.title : nil
    end

    # Is the portlet instanceable? This is defined in the XML configuration.
    # This method is overridden by Caterpillar.
    def instanceable?
      true
    end

#     def self.find_by_portletid(*args)
#     puts args.inspect
#       super(args)
#       # TODO: find caterpillar_portlets
#     end

    # searches both Liferay and Caterpillar portlets
    def self.find_by_name(name)
      begin
        pp = Web::PortletProperties.find_by_name(name)
        if pp
          p = self.find_by_portletid pp.portletid
          return p if p
        end

        pp = find_caterpillar_portlet(name) unless pp

        unless pp
          raise ActiveRecord::RecordNotFound
        else
          return self.create(
            :portletid => pp.portletid
          )
        end
      rescue
        STDERR.puts 'Portlet by name "%s" could not be found -- try "caterpillar db:migrate"' % name
        logger.debug $!.message
        return nil
      end
    end

  end
end