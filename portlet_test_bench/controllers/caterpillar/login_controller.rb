# encoding: utf-8


class Caterpillar::LoginController < Caterpillar::ApplicationController

  before_filter :authorize, :except => [ :login, :index, :logout ]

#   def initialize
#   end

  def index
    @user = session[:username]
    render :action => :index
  end

  def login
    if request.post?
      user = User.authenticate(params[:username],params[:password])
      if user
        session[:username] = user[:username]
#         STDERR.puts user.inspect
        flash[:notice] = "Logged in"
        redirect_to :action => :index
      else
        flash[:notice] = "Invalid credentials"
        render :action => :index
      end
    else
      render :action => :index
    end
  end

  def logout
    session[:username] = nil
    flash[:notice] = "Logged out"
    redirect_to :action => :index
  end


  def authorize
    redirect_to :action => :index
  end

end
