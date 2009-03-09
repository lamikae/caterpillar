require 'active_record'

module Web # :nodoc:
  # This table is not in the original lportal database.
  # This is created by a Caterpillar migration and contains metadata about portlets.
  class PortletProperties < ActiveRecord::Base
    set_table_name       :portletproperties

    belongs_to :portlet,
      :class_name => 'Web::Portlet',
      :foreign_key => :portletid

  end
end
