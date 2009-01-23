class PortletNames < ActiveRecord::Migration
  def self.up
    # dealing with tables that have no id is a pain with ActiveRecord,
    # and using the 'id' column for portletid does not work either,
    # ActiveRecord does not let that column to be set manually.
    create_table :portlet_names do |t|
      t.column :portletid, :string, :null => false
      t.column :name,      :string, :null => false
      t.column :title,     :string, :null => false
    end
  end

  def self.down
    drop_table :portlet_names
    #ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS portlet_names")
  end
end