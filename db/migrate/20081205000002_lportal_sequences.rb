require 'lportal'

class LportalSequences < ActiveRecord::Migration
  @@tables = [
    Account,
    Address,
    Announcement::Delivery,
    Announcement::Entry,
    Contact,
    Group,
    Permission,
    Phone,
    ResourceCode,
    Resource,
    Role,
    User,
    MB::Message,
    MB::Thread,
    MB::Discussion,
    MB::Category,
    Tag::Asset,
    Tag::Entry,
    Tag::Property,
    Web::Layout,
    Web::LayoutSet,
    Web::PortletPreferences,
    Web::Portlet
  ]

  def self.up
#     start = 8400000 # bigint = 8^8 bytes = 16 million bits, this is halfway up the possible range, rounded up
#     sql = ""
#     @@tables.each do |model|
#       table = model.table_name
#       primkey = model.primary_key
#       seq = table+'_'+primkey+'_seq'
#       sql += "CREATE SEQUENCE #{seq} START #{start}; ALTER TABLE #{table} ALTER #{primkey} SET default nextval('#{seq}');"
#     end
#     ActiveRecord::Base.connection.execute(sql)
  end

  def self.down
#     sql = ""
#     @@tables.each do |model|
#       table = model.table_name
#       primkey = model.primary_key
#       seq = table+'_'+primkey+'_seq'
#       sql += "ALTER TABLE #{table} ALTER #{primkey} DROP default; DROP SEQUENCE #{seq};"
#     end
#     ActiveRecord::Base.connection.execute(sql)
  end
end
