class Caterpillar::UserController < Caterpillar::ApplicationController
  layout 'basic'

  def initialize
    @user = {:name => "user1"}
  end
end
