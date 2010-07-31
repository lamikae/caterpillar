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
  #
  # Currently this consists of things that were constructed whenever needed during development,
  # and concidered general enough to be included here.
  #
  # link_to_liferay is deprecated, and is clearly a wrong way to solve the problem in question.
  # A better way has been constructed, but it is not perfect due to its dependency on a specific portlet.
  module Liferay
    include ActionView::Helpers::UrlHelper
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

    # Formulates a link to Liferay. DEPRECATED.
    #
    # Parameters:
    #  - obj is an instance of a model from the lportal library.
    #  - options
    def link_to_liferay(obj,options={})

      # Rails-portlet cannot pass the actual redirect parameter.
      # Workaround with JavaScript.
      redirect = 'javascript: history.go(-1)'

      title = 'n/a' # link title
      begin
        logger.debug "Formulating Liferay link for #{obj}"
        case obj.liferay_class

        ### group
        when 'com.liferay.portal.model.Group'
          STDERR.puts 'Called DEPRECATED method - use %s.path instead' % obj


        when 'com.liferay.portal.model.Layout'
          STDERR.puts 'Called DEPRECATED method - use %s.path instead' % obj


        ### user
        when 'com.liferay.portal.model.User'
          STDERR.puts 'Called DEPRECATED method - use %s.path instead' % obj


        ### blog
        when 'com.liferay.portlet.blogs.model.BlogsEntry'
          STDERR.puts 'FIXME: %s.path' % obj

        ### document library file
        #
        # tämä toimii hiukan eri logiikalla kuin toiset, koska
        # sama malli joutuu mallintamaan myös tyyppinsä tiedostopäätteestä
        when 'com.liferay.portlet.documentlibrary.model.DLFileEntry'
          STDERR.puts 'Called DEPRECATED method - use %s.path instead' % obj
          redirect_link=request.env["PATH_INFO"] # ei toimi portletissa

          label = 'Tiedostotyyppiä %s ei vielä tueta' % obj.type[:name]
            #_('Lataa tiedosto "%s"') % obj.asset.title
          case obj.type[:uuid]
            when :video
              label = _('Linkki videoon "%s"') % obj.asset.title
              link_to_exit_portlet( label, url_for(
                { :controller => :video,
                  :action => :asset,
                  :id => obj.asset.id,
                  :uid => @user.id,
                  :redirect => redirect_link
                }))

            when :pdf
              label = _('Linkki dokumenttiin "%s"') % obj.asset.title
              redirect = ''
              url = LiferayUrl.new(obj,nil,redirect).static_url
              link_to_exit_portlet( label, url )

          end


        ### galleriakuva
        when 'com.liferay.portlet.imagegallery.model.IGImage'
          STDERR.puts 'FIXME: %s.path' % obj
          base_url = "#{$LIFERAY_SERVER}/image/image_gallery"
          options.update(:use_large_igpreview => false) unless options[:use_large_igpreview]
          img_id = (options[:use_large_igpreview] == true ? obj.large.id : obj.small.id)

          img = link_to_exit_portlet(
            image_tag( "#{base_url}?img_id=#{img_id}", :alt => obj.description, :class => 'asset_image' ),
            "#{base_url}?img_id=#{obj.large.id}"
          )
          logger.debug img
          return img


        when 'com.liferay.portlet.journal.model.JournalArticle'
          STDERR.puts 'FIXME: %s.path' % obj
          url = LiferayUrl.new(obj,@user,redirect).instance_url
          link_to_exit_portlet( _('Lue koko artikkeli "%s"') % obj.asset.title, url )

        when 'com.liferay.portlet.messageboards.model.MBCategory'
          STDERR.puts 'Called DEPRECATED method - use %s.path instead' % obj


        when 'com.liferay.portlet.messageboards.model.MBMessage'
          STDERR.puts 'FIXME: %s.path' % obj
          url = LiferayUrl.new(obj,@user,redirect).instance_url
          link_to_exit_portlet( _('Lue viesti "%s"') % obj.asset.title, url )

  #       when 'com.liferay.portlet.messageboards.model.MBThread'

        when 'com.liferay.portlet.wiki.model.WikiPage'
          STDERR.puts 'FIXME: %s.path' % obj
          url = LiferayUrl.new(obj,@user,redirect).instance_url
          link_to_exit_portlet( _('Lue sivu "%s"') % obj.asset.title, url )

        else
          STDERR.puts 'Called DEPRECATED method, but no method can handle %s' % obj
          raise _('This type of link cannot be handled.')

        end

      rescue Exception => err
        logger.error '*** ERROR ***: %s' % err.message
        link_to_function( _('Cannot link to resource.'), "alert('#{err.message}')" )
      end
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
