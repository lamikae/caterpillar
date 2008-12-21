require 'active_record'

module Web
  class PortletPreferences < ActiveRecord::Base
    def title
      p = Caterpillar::LiferayPortlet.find_by_name(self.name)
      p ? p.title : nil
    end
  end
end