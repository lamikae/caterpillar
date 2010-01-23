class Caterpillar::JunitController < Caterpillar::ApplicationController

  # test response 200 OK
	def index
		render :text => ""
	end

	# Sets a session value so the single SESSION_KEY cookie is set.
	# The output XML prints the session ID and the JUnit test compares this
	# to the value from another request, and with the same cookie they should match.
	def session_cookie
		session[:the_time] = Time.now.to_s
		render :text => request.session_options.to_xml
	end
  
	def redirect
		redirect_to :action => :redirect_target
	end
	def redirect_target
		render :text => request.request_uri
	end

	# Sets multiple cookies and redirects.
 	def cookies_with_redirect
		cookies[:user_agent] = request.user_agent
		cookies[:the_time]   = Time.now.to_s
		redirect_to :action => "show_cookies"
	end
	def show_cookies
		render :text => cookies.to_xml
	end

	def post_redirect_get
		if request.post?
			session[:the_time] = Time.now.to_s
			redirect_to :action => :show_cookies
		else
			render :nothing => true, :status => 404
		end
	end
  
  def foobarcookies
   cookies[:foo] = "__g00d__";
    cookies[:bar] = "__yrcl__";
    cookies[:baz] = "__3ver__";
    render :nothing => true, :status => 200
  end
  def foobarcookiestxt
    logger.debug cookies.inspect
    if cookies.nil?
      txt = 'nil == cookies' 
    else
      txt = 
        begin
          "#{cookies[:foo]}#{cookies[:bar]}#{cookies[:baz]}"
        rescue Exception => e
          e.message()
        end
    end
    render :text => txt, :status => 200
  end

  # test foobarcookies with Liferay UID cookie and authentication.
  # 5 cookies altogether.  
  def cookies_liferay_auth
    txt =  "Liferay_UID: #{@uid}\n"
    txt += "#{cookies[:foo]}#{cookies[:bar]}#{cookies[:baz]}"
    render :inline => txt, :status => 200
  end
  before_filter :get_liferay_uid, :only => [:liferay_uid, :cookies_liferay_auth]

  #
  # authenticate these actions
  #
  before_filter :authorize_request, :only => [
    :authorized,
    :liferay_uid,
    :foobarcookies_auth,
    :foobarcookiestxt_auth,
    :cookies_liferay_auth
    ]
  alias :foobarcookies_auth :foobarcookies
  alias :foobarcookiestxt_auth :foobarcookiestxt

  # test session authorization
  def authorized
    render :nothing => true, :status => 200
  end
  
  # test Liferay UID cookie from portlet
  def liferay_uid
  	@uid = 'nil' if @uid.nil?
  	render :inline => @uid, :status => 200
  end

end
