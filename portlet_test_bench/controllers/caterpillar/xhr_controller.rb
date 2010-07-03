# encoding: utf-8
class Caterpillar::XhrController < Caterpillar::ApplicationController

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

end
