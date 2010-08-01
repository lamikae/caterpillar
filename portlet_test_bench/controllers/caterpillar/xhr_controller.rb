# encoding: utf-8
class Caterpillar::XhrController < Caterpillar::ApplicationController
  include Caterpillar::Helpers::Liferay
  
  def prototype
    # the page with the XHR triggers
    @javascripts = %w{prototype}
    render :action => 'time'
  end

  def jquery
    # the page with the XHR triggers
    @javascripts = %w{jquery-1.4.2.min}
    render :action => 'time'
  end

  def get_time
    send_data Time.now.to_s, :type => 'text/html'
  end

  # Liferay resource URL
  def resource
    logger.debug params
    @resource_url = cookies[:Liferay_resourceUrl]
    logger.debug @resource_url
    @r_u_params = params.dup
    #p url_for(:controller => Caterpillar::XhrController )
    
  end

end
