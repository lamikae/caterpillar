# encoding: utf-8


class Caterpillar::ResourceController < Caterpillar::ApplicationController

  def images
    @images = [
      { :description => "Rails logo", :file => 'portlet_test_bench/rails.png' }
#       { :description => "Image from a subdirectory", :file => 'lolcat/lolcat-monorail.jpg' }
    ]
  end

  # Inline text
  def inline
    render :inline => "Inline text"
  end

  # link to outside the portlet
  def exit_portlet
    @links = ['http://www.rubyonrails.org', 'http://www.google.fi/search?q=jsr286', {:action => :exit_portlet}]
    if params.include? :exit_portlet
      render :inline => 'portlet should now be exited'
    end
  end

end
