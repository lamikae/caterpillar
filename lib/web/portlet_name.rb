require 'active_record'

module Web # :nodoc:
  # This model does not appear in the lportal database. This is created by a migration and contains the portlet id => name mappings.
  class PortletName < ActiveRecord::Base
    set_table_name       :portlet_names
  end
end
