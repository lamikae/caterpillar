# encoding: utf-8
#--
# Copyright (c) 2007-2010 Mikael Lammmentausta
#               2010 Tulio Ornelas dos Santos
#
# See the file MIT-LICENSE included with the distribution for
# software license details.
#++

require 'rubygems'
require 'action_controller'

module Caterpillar # :nodoc:
module Helpers # :nodoc:
  
  # This module contains Rails helpers that provide methods to deal with various aspects
  # of portlet functionality in Liferay.
  module Liferay
    include ActionView::Helpers::TagHelper
    include Portlet
    
    class ResourceUrl
      include ActionController::UrlWriter
      
      require 'uri'
      
      attr_accessor :resource_uri
      attr_accessor :namespace
      attr_accessor :options
      attr_accessor :params
      
      def initialize(base_url, namespace = '', options = {}, params = {})
        @resource_uri = URI.parse(base_url)
        @namespace = namespace
        @options = options
        @params = params
      end
      
      def to_s()
        uri = @resource_uri.dup
        if @options.values.compact.empty?
          # pass
        else
          query = {}
          # unpack query
          unless uri.query.nil?
            uri.query.split('&').map do |p| p.split('=').reduce {|k,v| query.update({k => v})} end
          end
          # since url_for can't handle modularized controllers at this point,
          # offer an explicit route as a workaround.
          if @options[:route]
            route = @options[:route]
          else
            # need controller and action
            options = @options.dup
            options.update(:host => 'localhost') unless options[:host]
            options.update(:only_path => true)
            if options[:action].nil? then options.update(:action => 'index') end
            route = url_for(options)
          end
          query.update('_%s_%s' % [@namespace,'railsRoute'] => route)
          @params.each_pair do |k,v|
            query.update('_%s_%s' % [@namespace,k] => v)
          end
          # pack query
          uri.query = query.each_pair.map{|k,v| '%s=%s' % [k,v]}.join('&')
        end
        return '%s://%s:%i%s' % [uri.scheme, uri.host, uri.port, uri.request_uri]
      end
      
    end
    
    def resource_url_cookie
      cookies[:Liferay_resourceUrl]
    end
    
    def preferences_cookie
      cookies[:Liferay_preferences]
    end
    
    # Formulate resource URL for Liferay.
    # The request will be handled by serveResource().
    # The cookie "Liferay_resourceUrl" should be automatically included into 
    # available cookies by "rails-portlet".
    def liferay_resource_url(_params, resource_url=resource_url_cookie)
      if resource_url.nil? then return raise "resource_url is needed!" end
      params = _params.dup # create duplicate params, do not modify originals!
      
      options = {
        :controller => params.delete(:controller),
        :action => params.delete(:action),
        :route => params.delete(:route)
        }
      
      res = ResourceUrl.new(resource_url)
      res.options = options
      res.namespace = @namespace || namespace_cookie
      res.params = params
      #p res
      return res.to_s
=begin
      if options[:controller].nil? then return resource_url end
      #if route_params[:action].nil? then action = :index end
      url = "#{resource_url}&#{namespace}railsRoute=/#{path}"
      unless params.empty?
        url += '?'
        params.keys.each do |key|
          url += "#{key}=#{params[key]}&"
        end
        url.gsub!(/&$/, '')
      end
      url
=end
    end

    # Gets portlet preferences from a cookie (Liferay_preferences) and generates
    # a hash with it. Returns nil if cookie do not exists or the value is nil.
    #
    def get_liferay_preferences(value = preferences_cookie)
      preferences = {}
      if value and (not value.empty?)
        value.split(";").each do |pair|
          if pair.nil? or pair.empty? then next end
          result = pair.split("=")
          preferences[result[0].intern] = result[1]
        end
        return preferences
      end
      nil
    end

    # Link that the rails-portlet will leave unparsed.
    def link_to_exit_portlet(name, options = {}, html_options = {})
      link_to(name, url_to_exit_portlet(options), html_options)
    end

    # Appends parameters "exit_portlet=true" into the url.
    # Url might be either Hash or String.
    def url_to_exit_portlet(url)
      parameters = { :exit_portlet => 'true' }

      # append parameters to the url
      if url.is_a? Hash
        url.update parameters

      elsif url.is_a? String
        if url[/\?[\w]*\=/]     # url has parameters
          delimiter = '&amp;'
        else                    # no parameters
          delimiter = '?'
        end
        url += "#{delimiter}#{parameters.keys.first}=#{parameters.values.first}"

      end
      return url
    end

  end
end
end
