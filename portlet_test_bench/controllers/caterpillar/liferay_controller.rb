# encoding: utf-8
class Caterpillar::LiferayController < Caterpillar::ApplicationController

  # Import security filters
  include Caterpillar::Security
  secure_portlet_sessions(:only => :authorized_sessions)


  def session_variables
    @uid = params[:uid]
    @gid = params[:gid]
  end
  
  def authorized_sessions
    render :inline => 'Request was authorized via shared secret'
  end

end