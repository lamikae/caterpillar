class LportalPortlets < ActiveRecord::Migration
  def self.up
    create_table :lportal_portlets do |t|
      t.column :name,  :string
      t.column :title, :string
    end
  end

  def self.down
    drop_table :lportal_portlets
  end
end
