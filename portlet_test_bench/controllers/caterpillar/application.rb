class Caterpillar::ApplicationController < ActionController::Base

  layout 'basic'

  helper 'Caterpillar::Application'

  before_filter :is_test_selected


  # Rails-portlet has session cookie support.
  #session :disabled => true
  
  # # #   Security
  
  # This is a rudimentary firewall against simple spoofing.
  # In production the app should not receive HTTP requests from
  # anywhere else than from Java HttpClient, except XHRs.
  #
  # Exceptions should be added (for resources such as images) 
  # in respective controllers.
  #
  def authorize_agent
    # make development and test ENV to pass
    return true if RAILS_ENV != 'production'

    # XHR always passes
    return true if request.xhr?

    # check the user agent
    agent = request.env['HTTP_USER_AGENT']
    unless agent=='Jakarta Commons-HttpClient/3.1'
      logger.warn 'Someone from IP %s may be spoofing using agent %s' % [request.env['REMOTE_ADDR'], agent]
      render :nothing => true, :status => 404
    end
  end

	before_filter :authorize_agent, :only => :cookiejar


  # Get the UID from the cookie.
  # There is an error if the key does not exist,
  # meaning the portlet either did not handle cookie correctly
  # or someone tried to spoof by making up a fake cookie.
  def get_cookie_uid
  	secret =
    #logger.debug     ActionController::Base.session_options_for(nil,nil)[:secret]
    # On Rails 2.3:
    	ActionController::Base.session_options[:secret]

    uid_key = secret+"_UID"
    logger.debug "Key: "+uid_key
    
    unless cookies.nil? or cookies[uid_key].nil?
      @uid = cookies[uid_key]
      logger.debug("Accepted UID %s" % @uid)
      return true
    end

    logger.debug("UID key is not present in %s" % cookies.inspect)
    render :nothing => true, :status => 404
  end


	# Handles out a cookie.
	# Because session needs the cookie to maintain its state,
	# a new cookie is sent with the response automatically.
  def cookiejar
  	logger.debug "Handling cookie to " + request.env['REMOTE_ADDR']
    # TODO: handle security key from request params, now just reply on proper user agent
    # need to set at least one session or cookie key here.
		cookies[:rng_security_key] = "99999"; # Debian style random number generator
		render :nothing => true, :status => 200 
  end

  # If controller is not ApplicationController, test is selected.
  def is_test_selected
    @test_is_selected = self.class.to_s[/Application/].nil?
  end
  
  

end