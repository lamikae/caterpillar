# encoding: utf-8
#--
# Copyright (c) 2010 Tulio Ornelas dos Santos
#
# See the file MIT-LICENSE included with the distribution for
# software license details.
#++

module Caterpillar
  
  # Add some portlet support
  #
  module PortletSupport
  
    # Gets portlet preferences from a cookie (Liferay_preferences) and generates
    # a hash with it. Returns nil if cookie do not exists or the value is nil.
    # XXX: should not this be moved to Helpers::Liferay ?
    #
    def get_liferay_preferences(value = cookies[:Liferay_preferences])
      preferences = {}
      if value and (not value.empty?)
        value.split(";").each do |pair|
          if pair.nil? or pair.empty? then next end
          result = pair.split("=")
          preferences[result[0].intern] = result[1]
        end
        return preferences
      end
      nil
    end

  end
end
