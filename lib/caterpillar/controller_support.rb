module Caterpillar
  module ControllerSupport
  
    def get_liferay_preferences
      value = cookies[:Liferay_preferences]
  
      puts "\nLiferay_preferences => #{value}\n"
  
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