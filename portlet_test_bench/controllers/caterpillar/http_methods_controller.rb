# encoding: utf-8


class Caterpillar::HttpMethodsController < Caterpillar::ApplicationController

  def post
    @postcode = 'SW1A 0AA'

    if request.post?
      @msg      = params[:msg]
      @checkbox = params[:checkbox]
      if params[:postcode]
        @msg = params[:postcode][@postcode]
      end
    end
 
    render :action => :post
  end

  def post_and_redirect
    @msg      = '"%s" passed from POST to GET' % params[:msg_get] if request.get? and params[:msg_get]
    if request.post?
      redirect_to :action => :post_and_redirect, :msg_get => params[:msg]
    end
  end

  def parameter
    @params = params
    @params.delete :action
    @params.delete :controller
  end

  def redirect_back
    redirect_to :back
  end

  def redirect_action
    flash[:info] = 'This message was set in the action before redirect'
    redirect_to :action => :redirect, :x => true
  end

#   def redirect_target
#     render :action => :redirect
#   end

end
