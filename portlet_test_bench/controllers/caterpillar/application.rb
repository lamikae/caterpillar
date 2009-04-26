class Caterpillar::ApplicationController < ActionController::Base

  layout 'basic'

  before_filter :is_test_selected

  def is_test_selected
    @test_is_selected = self.class.to_s[/Application/].nil?
  end

end
