# encoding: utf-8
#--
# (c) Copyright 2008,2009 Mikael Lammentausta
# See the file LICENSES.txt included with the distribution for
# software license details.
#++

module Caterpillar # :nodoc:
  # Portlet navigation on Rails.
  #
  # Caterpillar installs a partial 'caterpillar/navigation' into your views,
  # along with an image and a CSS file.
  # You need to add a filter 'caterpillar' which you will only load in
  # development environment - in production the portlet container will be the
  # 'window manager'. This partial helps you to navigate between your portlets.
  #
  # This will go to your ApplicationController:
  #   if RAILS_ENV=='development'
  #     before_filter :caterpillar
  #   end
  #
  #   def caterpillar # :nodoc:
  #     @caterpillar_navigation = Caterpillar::Navigation.rails
  #     @caterpillar_navigation_defaults = {
  #       :uid => 13904,
  #       :gid => 13912
  #     }
  #   end
  #
  # This will go the body of your layout:
  #   <% if @caterpillar_navigation -%>
  #     <%= render :partial => "caterpillar/navigation" %>
  #   <% end -%>
  #
  class Navigation

    # Method for formulating the portlets hash in Rails environment
    def self.rails
      config = Util.eval_configuration
      config.routes = Util.parse_routes(config)
      return Util.categorize(Parser.new(config).portlets)
    end

  end
end