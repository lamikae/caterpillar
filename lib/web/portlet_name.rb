require 'active_record'

module Web # :nodoc:
  # This model does not appear in the lportal database. This is created by a migration and contains the portlet id => name mappings.
  class PortletName < ActiveRecord::Base # :nodoc:
    set_table_name       :web_portlet_names
  end
end
