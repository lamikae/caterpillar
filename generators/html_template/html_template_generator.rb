# encoding: utf-8

class HtmlTemplateGenerator < Rails::Generator::Base

  attr_accessor :project_name

  def after_generate
    STDOUT.puts "Done!"
  end

  def manifest
    record do |m|
      @project_name = RAILS_ROOT.split('/')[-1]
      m.template('application.html.erb', 'app/views/layouts/application.html.erb')
    end
  end
  
end
