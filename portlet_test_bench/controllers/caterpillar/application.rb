class Caterpillar::ApplicationController < ActionController::Base

  layout 'basic'

  before_filter :find_navigation

  def find_navigation
    if self.class.to_s=='Application'
      @navigation = false
    else
      @navigation = true
    end
  end

end
