require 'test_helper'
require File.dirname(File.expand_path(__FILE__))+'/test_helper'

class RailsTaskTest < Caterpillar::TestCase

  def test_generated_rails_project
    project_name = 'caterpillar_rails_test'

#    Rake::Task['rails'].execute(project_name)
    `ruby -S caterpillar rails #{project_name}`
    assert FileTest.directory? project_name
    assert File.read("#{project_name}/config/environment.rb") =~ /caterpillar/
    assert FileTest.directory? "#{project_name}/vendor/plugins/caterpillar-#{Caterpillar::VERSION}"
    assert FileTest.exists? "#{project_name}/config/warble.rb"
    assert FileTest.exists? "#{project_name}/config/portlets.rb"
    FileUtils.rm_rf project_name
  end
    
  
end
