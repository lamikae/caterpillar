# encoding: utf-8


module Caterpillar::JunitHelper

  def xhr_onclick_tag # :nodoc:
    button_to_remote('send onclick POST', :update => 'onclick_resp', :url => { :action => :xhr_hello }) +\
    '<div id="onclick_resp"></div>'
  end

  def xhr_form_tag # :nodoc:
    form_remote_tag( :update => 'form_resp', :url => { :action => :xhr_hello }) do
      '<div>' + submit_tag('send form POST') + '</div>'
    end
    '<div id="form_resp"></div>'
  end

end
