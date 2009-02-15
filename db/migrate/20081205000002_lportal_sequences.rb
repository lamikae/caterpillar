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
    MB::Category,
    MB::Discussion,
    MB::Message,
    MB::MessageFlag,
    MB::StatsUser,
    MB::Thread,
    RatingsStats,
    SocialActivity,
    SocialRelation,
    Tag::Asset,
    Tag::Entry,
    Tag::Property,
    Web::Layout,
    Web::LayoutSet,
    Web::PortletPreferences,
    Web::Portlet
  ]

  def self.up
    STDOUT.puts 'This migration does not do anything.'
    STDOUT.puts 'The process is not refined properly yet, and could be quite disastrous if reverted unappropriately.'
    STDOUT.puts 'If you are sure you need the sequences, copy this file to db/migrate and modify it.'
    STDOUT.puts __FILE__

    start = 8400000 # bigint = 8^8 bytes = 16 million bits, this is halfway up the possible range, rounded up
    sql = ""
    @@tables.each do |model|
      table = model.table_name
      primkey = model.primary_key
      seq = table+'_'+primkey+'_seq'
      sql += "CREATE SEQUENCE #{seq} START #{start}; ALTER TABLE #{table} ALTER #{primkey} SET default nextval('#{seq}');"
    end

    # To activate, uncomment this line.
    #ActiveRecord::Base.connection.execute(sql)
  end

  # This is VERY DANGEROUS and may lead to breakage.
  def self.down
    # sql = ""
    # @@tables.each do |model|
    #   table = model.table_name
    #   primkey = model.primary_key
    #   seq = table+'_'+primkey+'_seq'
    #   sql += "ALTER TABLE #{table} ALTER #{primkey} DROP default; DROP SEQUENCE #{seq};"
    # end
    # ActiveRecord::Base.connection.execute(sql)
  end
end
