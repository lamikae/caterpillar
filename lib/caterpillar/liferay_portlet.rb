require 'active_record'

module Caterpillar
  # This model does not appear in the lportal database. This is created by a migration and contains the portlet id => name mappings.
  class LiferayPortlet < ActiveRecord::Base
    set_table_name :lportal_portlets
  end
end