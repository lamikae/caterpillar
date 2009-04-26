class UserController < ApplicationController
  layout 'basic'

  def initialize
    @user = {:name => "user1"}
  end
end
