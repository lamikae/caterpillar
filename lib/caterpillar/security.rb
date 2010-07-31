# encoding: utf-8
#--
# (c) Copyright 2010 Mikael Lammentausta
#
# See the file MIT-LICENSE included with the distribution for
# software license details.
#++

module Caterpillar # :nodoc:

  # Security methods for Rails controllers.
  # Request authentication is based on shared secret key, that is the Rails' session secret.
  # 
  #
  # Filters (see Caterpillar::Security::InstanceMethods)
  # - authorize_agent
  # - authorize_request
  # - get_liferay_uid
  #
  # To enable session security, insert this into ApplicationController:
  #   include Caterpillar::Security
  #   secure_portlet_sessions
  #   before_filter [:authorize_agent, :authorize_request], :only => :get_liferay_uid
  #   before_filter :get_liferay_uid
  #
  module Security
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
    end
    
    module ClassMethods # :nodoc:
      def secure_portlet_sessions(options = {})
        class_eval <<-EOV
          include Caterpillar::Security::InstanceMethods
        EOV
      end
    end

    module InstanceMethods

    # This is a rudimentary protection against simple spoofing in production environment.
    #
    # Only accepts HTTP requests from the Java HttpClient.
    #
    # XHR is a different issue, it is not (yet) supported by the portlet,
    # so it will always pass this check.
    #
    # Exceptions should be added (for resources such as images) 
    # in respective controllers.
    #
    # This filter will always be passed in RAILS_ENV development and test, because you
    # most likely want to develop portlets sometimes without the Liferay environment.
    # If you want this to change, send in a feature request to the developers or the
    # bugs mailing list.
    #
    def authorize_agent
      # make development and test ENV to pass
      return true if ( RAILS_ENV == 'development' || RAILS_ENV == 'test' )

      # XHR always passes
      return true if request.xhr?

      # check the user agent
      agent = request.env['HTTP_USER_AGENT']
      unless agent=='Jakarta Commons-HttpClient/3.1'
        logger.warn 'Someone from IP %s may be spoofing using agent %s' % [request.env['REMOTE_ADDR'], agent]
        render :nothing => true, :status => 404
      end
    end

    # Authorize the request.
    #
    # The request needs to pass in "session_secret" cookie with
    # the value of session secret.
    #
    def authorize_request
      if !cookies.nil? and !cookies[:session_secret].nil?
      	if cookies[:session_secret] == Caterpillar::Security.get_secret
          logger.debug "Passes security check"
          return true
        end
      end
      logger.debug("Session secret is not present in %s" % cookies.inspect)
      logger.warn 'Someone from IP %s may be spoofing' % request.env['REMOTE_ADDR']
      render :nothing => true, :status => 403
    end


    # Get the Liferay UID from cookie.
    def get_liferay_uid
      uid_key = 'Liferay_UID'
      unless cookies.nil? or cookies[uid_key].nil?
        @uid = cookies[uid_key]
        logger.debug("Liferay UID %s" % @uid)
      else
        logger.debug("UID key is not present in cookies %s" % cookies.inspect)
      end
    end


    end # module


    # Return Rails' session key    
    def self.get_session_key
      # Rails before 2.3 had a different way
      if defined?(RAILS_GEM_VERSION) and RAILS_GEM_VERSION.gsub('.','').to_i < 230
        ActionController::Base.session_options_for(nil,nil)[:session_key]
      # On Rails 2.3:
      else
        key = ActionController::Base.session_options[:key]
        return key unless key.nil?
        # try session_key
        key = ActionController::Base.session_options[:session_key]
        return key unless key.nil?
        # XXX: Rails changed sometime during 2.3.8 ..
        STDERR.puts 'Failed to read session key - consider this a bug'
        return nil
      end
    end

    # Return Rails' secret    
    def self.get_secret
      # Rails before 2.3 had a different way
      if RAILS_GEM_VERSION.gsub('.','').to_i < 230
        ActionController::Base.session_options_for(nil,nil)[:secret]
      # On Rails 2.3:
      else
        ActionController::Base.session_options[:secret]
      end
    end

  end
end
