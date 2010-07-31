# encoding: utf-8


class Caterpillar::SessionController < Caterpillar::ApplicationController
  include Caterpillar::Helpers::Portlet

  before_filter :get_namespace, :only => :namespace

  # flash message.
  def flash_msg
    flash[:info] = "Flash works on %s" % request.request_method.to_s.upcase
    redirect_to :action => :flash_display
  end


	def cookie_with_redirect
		cookies[:the_time] = Time.now.to_s
		redirect_to :action => "cookie_with_redirect_target"
	end
	def cookie_with_redirect_target
		cookie_value = cookies[:the_time]
		render(:text => "The cookie says it is #{cookie_value}")
	end

	def cookie
		cookies[:platform] = RUBY_PLATFORM
		cookies[:the_time] = Time.now.to_s
    cookies.each do |cookie|
      logger.debug cookie.inspect
    end
		session[:testvalue] = "Session data set at " + Time.now.to_s
  end

#   def _id
#     render :inline => session.session_id.inspect
#   end
# 
# 
#   # inspect the request variables
#   def req
#     s = "<html><body>"
# 
#     request.env.each_pair do |key,value|
#       s += key
#       s += " => "
#       s += value unless value.nil?
#       s += "<br />"
#     end
# 
#     s += "</body></html>"
#     render :inline => s
#   end

end
