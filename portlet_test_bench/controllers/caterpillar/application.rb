STDERR.puts 'foo'
# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class Caterpillar::ApplicationController < ActionController::Base
  # helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
#  protect_from_forgery :secret => 'f511e08e5bb29acd248ad49c093e69e9'

  layout 'bare'

end
