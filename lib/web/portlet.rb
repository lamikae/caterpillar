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

    def title
      p = Web::PortletName.find_by_portletid(self.portletid)
      p ? p.title : nil
    end

  end
end