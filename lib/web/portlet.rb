# encoding: utf-8


module Web # :nodoc:
  # Adds Caterpillar portlets to available portlets.
  class Portlet < ActiveRecord::Base

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

#     def self.find_by_portletid(*args)
#     puts args.inspect
#       super(args)
#       # TODO: find caterpillar_portlets
#     end

    # searches both Liferay and Caterpillar portlets
    # TODO: DRY up with super
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
