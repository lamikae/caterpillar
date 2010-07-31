# encoding: utf-8
#--
# Copyright (c) 2010 Mikael Lammmentausta, Tulio Ornelas dos Santos
#
# See the file MIT-LICENSE included with the distribution for
# software license details.
#++

require 'rubygems'
require 'action_controller'

module Caterpillar # :nodoc:
module Helpers # :nodoc:
  module Portlet

    # Get portlet namespace from cookie set by rails-portlet
    def namespace_cookie
      cookies[:Portlet_namespace]
    end

    # Set instance variable @namespace
    def get_namespace
      @namespace = namespace_cookie
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
end
  