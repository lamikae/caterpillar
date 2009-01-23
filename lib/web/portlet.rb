require 'active_record'

module Web
  class Portlet < ActiveRecord::Base
    def title
      p = Web::PortletName.find_by_portletid(self.portletid)
      p ? p.title : nil
    end
  end
end