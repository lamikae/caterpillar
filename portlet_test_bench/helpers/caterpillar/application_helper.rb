# FIXME: caterpillar does not automatically update helpers without server restart
module Caterpillar::ApplicationHelper
  include Caterpillar::Helpers::Liferay

  # junit helpers ---

  def xhr_get_tag # :nodoc:
    button_to_remote('send GET', :update => 'get_resp', :url => { :action => :xhr_get }) +\
    '<p id="get_resp"></p>'
  end

  def xhr_post_tag # :nodoc:
    form_remote_tag(:update => 'post_resp', :url => { :action => :xhr_post }) do
      '<div>' + submit_tag('send POST') + '</div>'
    end
    '<p id="post_resp"></p>'
  end

end
