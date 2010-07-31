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
       
    # Send the rendered page in a file to serveResource method
    #
    def ajax_response params = {}
      if params[:template]
        content = render_to_string :template => params[:template]
      else
        content = render_to_string
      end

      send_data resposta, :type => 'text/html', :filename => "content_#{request.session_options[:id]}.html"
    end

  end
end
