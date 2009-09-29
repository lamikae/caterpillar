class Caterpillar::ApplicationController < ActionController::Base

  layout 'basic'

  helper 'Caterpillar::Application'

  before_filter :is_test_selected

  # Rails-portlet does not have session cookie support.
  # But flash messages require this.
  #session :disabled => true

  # If controller is not ApplicationController, test is selected.
  def is_test_selected
    @test_is_selected = self.class.to_s[/Application/].nil?
  end

end