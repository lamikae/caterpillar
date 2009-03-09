class PortletProperties < ActiveRecord::Migration
  def self.up
    # dealing with tables that have no id is a pain with ActiveRecord,
    # and using the 'id' column for portletid does not work either,
    # ActiveRecord does not let that column to be set manually.
    create_table :portletproperties do |t|
      t.column :portletid,    :string,  :null => false
      t.column :name,         :string,  :null => false
      t.column :title,        :string,  :null => false
      t.column :instanceable, :boolean, :null => false, :default => true
    end
    ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS portlet_names")
  end

  def self.down
    drop_table :portletproperties
    #ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS portletproperties")
  end
end