# encoding: utf-8
#--
# Copyright (c) 2007-2010 Mikael Lammmentausta
#
# See the file LICENSES.txt included with the distribution for
# software license details.
#++

require 'rubygems'
require 'action_controller'

module Caterpillar
module Helpers
  
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

    def liferay_resource_url(params, resource_url = cookies[:Liferay_resourceUrl])
      if resource_url.nil? then return raise "resource_url is needed!" end
      
      controller = params.delete :controller
      action = params.delete :action
      
      if controller.nil? then return resource_url end
      if action.nil? then action = :index end
      
      url = "#{resource_url}&railsRoute=/#{controller}/#{action}"
      
      unless params.empty?
        url += '?'
        params.keys.each do |key|
          url += "#{key}=#{params[key]}&"
        end
        url.gsub!(/&$/, '')
      end
      
      url
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