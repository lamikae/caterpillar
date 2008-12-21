require 'active_record'

module Web
  class Portlet < ActiveRecord::Base
    def title
      p = Caterpillar::LiferayPortlet.find_by_name(self.portletid)
      p ? p.title : nil
    end
  end
end