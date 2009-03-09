require 'rubygems'
require 'active_record'

module Web
  class PortletPreferences < ActiveRecord::Base
    def title
      p = Web::PortletProperties.find_by_portletid(self.name)
      p ? p.title : nil
    end
  end
end