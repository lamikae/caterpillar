class Caterpillar::LiferayController < Caterpillar::ApplicationController

  def session_variables
    @uid = params[:uid]
    @gid = params[:gid]
  end

end