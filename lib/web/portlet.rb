require 'active_record'

module Web
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

    # read-only
    def title
      p = Web::PortletName.find_by_portletid(self.portletid)
      p ? p.title : nil
    end

    # Is the portlet instanceable? This is defined in the XML configuration.
    # TODO: parse to database.
    def instanceable?
      return false if self.portletid=='58' # login
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
        pn = Web::PortletName.find_by_name(name)
        if pn
          p = self.find_by_portletid pn.portletid
          return p if p
        end
        
        pn = find_caterpillar_portlet(name) unless pn
        
        unless pn
          raise ActiveRecord::RecordNotFound
        else
          return self.create(
            :portletid => pn.portletid
          )
        end
      rescue
        STDERR.puts 'portlet by name %s could not be found -- try "caterpillar db:migrate"' % name
        raise $!
      end
    end

  end
end