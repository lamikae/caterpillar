require File.expand_path(File.dirname(__FILE__) + "/../init")

class Caterpillar::TestCase < Test::Unit::TestCase # :nodoc:
  #fixtures [ :portletitem, :portlet_names, :portletpreferences ]

  def setup
    @config = Caterpillar::Util.eval_configuration
    @config.routes = Caterpillar::Util.parse_routes(@config)
    @portlets = Caterpillar::Parser.new(@config).portlets
  end

  def default_test
    assert true
  end
end
