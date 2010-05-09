# encoding: utf-8


class Caterpillar::JsController < Caterpillar::ApplicationController

  def simple
    @javascripts = false
    render :layout => false
  end

  # the :defaults JavaScripts in javascript_include_tag
  def defaults
    @javascripts = false # do not include any javascripts
    id = params[:id]
    if id then
      render :template => "js/#{id}"
    else
      render :template => 'js/defaults'
    end
  end

  def prototype
    @javascripts = ['prototype']
  end

  def scriptaculous
    @javascripts = ['prototype','effects','controls']
  end

  def jquery
    @javascripts = ['jquery','jquery-ui','jrails']
  end

  def dragndrop
    #@javascript = ['prototype','scriptaculous']
#     @javascripts = ['prototype','effects','dragdrop','controls']
#     @javascripts = ['jquery','jquery-ui','jrails']
    @javascripts = :defaults
  end

  def link_to_post
    @msg = params[:msg] || 'method was GET'
  end

  def link_to_post_action
    msgs = ['successful','ok','it works','dandy']
    redirect_to :action => :link_to_post, :msg => msgs[rand(msgs.size)]
  end

  #######

  def highlight_test
    render :update do |page|
      page[:highlight_test].visual_effect(:highlight)
    end
  end

  def appear_test
    render :update do |page|
      page.visual_effect 'toggle_appear', "appear_test"
    end
  end

  def toggle_blind_test
    render :update do |page|
      page.visual_effect 'toggle_blind', "toggle_blind_test"
    end
  end

  def receive_drop
    render :update do |page|
      page[:drop_status].appear
      page[:drop_status].replace_html('Received: %s' % params[:id])
    end
  end

end
