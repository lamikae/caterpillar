module Caterpillar
module Helpers
  module Liferay
#     include ActionView::Helpers::UrlHelper
#     include ActionView::Helpers::TagHelper

    # Formulates a link to Liferay.
    # Parameters:
    #  - obj is an instance of a model from the lportal library.
    #  - options
    def link_to_liferay(obj,options={})
      options.update(:use_large_igpreview => false) unless options[:use_large_igpreview]

      # Rails-portlet cannot pass the actual redirect parameter.
      # Workaround with JavaScript.
      redirect = 'javascript: history.go(-1)'

      title = 'n/a' # link title
      begin
        STDERR.puts 'This method is DEPRECATED - use obj.path instead'
        logger.debug "Formulating Liferay link for #{obj}"
        case obj.liferay_class

        ### group
        when 'com.liferay.portal.model.Group'
#           title = (obj.name.empty? ? obj.owner.fullname : obj.name)
#           urls = LiferayUrl.new(obj,nil,nil).static_url
#           logger.debug urls
#           if options[:private]
#             label = _('yksityiset sivut')
#             urls[:private] ?
#               link_to_exit_portlet( label, urls[:private] ) :
#               link_to_function(
#                 label, "alert('%s')" % _('Yhteisöllä ei ole yksityisiä sivuja'))
#           else
#             label = _('julkiset sivut')
#             urls[:public] ?
#               link_to_exit_portlet( label, urls[:public] ) :
#               link_to_function(
#                 label, "alert('%s')" % _('Yhteisöllä ei ole julkisia sivuja'))
#           end


# siirretty malliin
#         when 'com.liferay.portal.model.Layout'
#           url = LiferayUrl.new(obj).static_url
#           return url_to_exit_portlet(url)


        ### user
        when 'com.liferay.portal.model.User'
#           urls = LiferayUrl.new(obj,nil,nil).static_url
#           #logger.debug urls
#           if options[:private]
#             label = options[:label]
#             label ||= _('yksityiset sivut')
#             urls[:private] ?
#               link_to_exit_portlet( label, urls[:private] ) :
#               link_to_function(
#                 label, "alert('%s')" % _('Tunnuksella ei ole yksityisiä sivuja'))
#           else
#             label = options[:label] || _('julkiset sivut')
#             urls[:public] ?
#               link_to_exit_portlet( label, urls[:public] ) :
#               link_to_function(
#                 label, "alert('%s')" % _('Tunnuksella ei ole julkisia sivuja'))
#           end


        ### blog
        when 'com.liferay.portlet.blogs.model.BlogsEntry'
          title = _('Linkki blogimerkintään "%s"') % obj.title
          url = LiferayUrl.new(obj,@user,redirect).instance_url
          link_to_exit_portlet( title, url )


        ### document library file
        #
        # tämä toimii hiukan eri logiikalla kuin toiset, koska
        # sama malli joutuu mallintamaan myös tyyppinsä tiedostopäätteestä
        when 'com.liferay.portlet.documentlibrary.model.DLFileEntry'
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
          base_url = "#{$LIFERAY_SERVER}/image/image_gallery"
          img_id = (options[:use_large_igpreview] == true ? obj.large.id : obj.small.id)

          img = link_to_exit_portlet(
            image_tag( "#{base_url}?img_id=#{img_id}", :alt => obj.description, :class => 'asset_image' ),
            "#{base_url}?img_id=#{obj.large.id}"
          )
          logger.debug img
          return img


        when 'com.liferay.portlet.journal.model.JournalArticle'
          url = LiferayUrl.new(obj,@user,redirect).instance_url
          link_to_exit_portlet( _('Lue koko artikkeli "%s"') % obj.asset.title, url )

        when 'com.liferay.portlet.messageboards.model.MBCategory'
#           url = LiferayUrl.new(obj,@user,redirect).static_url
#           link_to_exit_portlet( obj.name, url )


        when 'com.liferay.portlet.messageboards.model.MBMessage'
          url = LiferayUrl.new(obj,@user,redirect).instance_url
          link_to_exit_portlet( _('Lue viesti "%s"') % obj.asset.title, url )

  #       when 'com.liferay.portlet.messageboards.model.MBThread'

        when 'com.liferay.portlet.wiki.model.WikiNode'
          logger.debug "WikiNode"
  #         url = LiferayUrl.new(obj,@user,redirect).instance_url
  #         link_to_exit_portlet( _('Lue sivu "%s"') % obj.asset.title, url )

        when 'com.liferay.portlet.wiki.model.WikiPage'
          logger.debug "WikiPage"
          url = LiferayUrl.new(obj,@user,redirect).instance_url
          link_to_exit_portlet( _('Lue sivu "%s"') % obj.asset.title, url )

        else
          logger.debug obj.liferay_class
          raise _('Tämän tyyppistä linkkiä ei vielä hallita')

        end

      rescue Exception => err
        logger.error '*** ERROR ***: %s' % err.message
        link_to_function( _('Kohteeseen ei voi linkittää.'), "alert('#{err.message}')" )
      end
    end


    def url_to_exit_portlet(url)
      directive = { :exit_portlet => 'true' }

      if url.is_a? Hash
        url.update directive

      elsif url.is_a? String
        if url[/\?[\w]*\=/]     # url has parameters
          delimiter = '&amp;'
        else                    # no parameters
          delimiter = '?'
        end
        url += "#{delimiter}#{directive.keys.first}=#{directive.values.first}"

      end
      return url
    end


    # formulates a link that the rails286-portlet will leave unparsed.
    def link_to_exit_portlet(label, url)
      link_to label, url_to_exit_portlet(url)
    end

  end
end
end