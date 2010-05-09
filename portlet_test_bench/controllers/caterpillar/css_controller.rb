# encoding: utf-8


class Caterpillar::CssController < Caterpillar::ApplicationController
  def simple
    render :layout => false
  end

  def background
    render :layout => false
  end
end
