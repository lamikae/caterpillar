class Caterpillar::ApplicationController < ActionController::Base

  layout 'basic'

  helper 'Caterpillar::Application'

  # Rails-portlet has session cookie support.
  #session :disabled => true

  # Require secure cookies,
  # imports a few filters and the cookiejar action.
  include Caterpillar::Security
  secure_portlet_sessions

  # only handle cookies to trusted agents
  before_filter :authorize_agent, :only => :cookiejar


  ### Used for navigating the test bench

  # If controller is not ApplicationController, test is selected.
  def is_test_selected
    @test_is_selected = self.class.to_s[/Application/].nil?
  end
  
  before_filter :is_test_selected
  

end
