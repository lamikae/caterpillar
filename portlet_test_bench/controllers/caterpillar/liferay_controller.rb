# encoding: utf-8
class Caterpillar::LiferayController < Caterpillar::ApplicationController

  # Import security filters
  include Caterpillar::Security
  secure_portlet_sessions(:only => :authorized_sessions)
  
  # UID & GID filters
  include Caterpillar::Helpers::Liferay
  before_filter :get_liferay_uid, :only => :session_variables
  before_filter :get_liferay_gid, :only => :session_variables


  def session_variables
  end
  
  def authorized_sessions
    render :inline => 'Request was authorized via shared secret'
  end

end