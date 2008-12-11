class Caterpillar::TestCase < Test::Unit::TestCase # :nodoc:
  def setup
    @config = Caterpillar::Util.eval_configuration
    @config.routes = Caterpillar::Util.parse_routes(@config)
    @portlets = Caterpillar::Parser.new(@config).portlets
  end
end