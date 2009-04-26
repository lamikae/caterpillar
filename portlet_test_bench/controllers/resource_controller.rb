class ResourceController < ApplicationController
  layout 'basic'

  def images
    @images = [
      { :description => "Rails logo", :file => 'rails.png' },
      { :description => "Image from a subdirectory", :file => 'lolcat/lolcat-monorail.jpg' }
    ]
    render :template => 'resource/images'
  end

  # Inline text
  def inline
    render :inline => "Inline text"
  end

  # link to outside the portlet
  def exit_portlet
    if params.include? :exit_portlet
      render :inline => 'portlet should now be exited'
    end
  end

end
