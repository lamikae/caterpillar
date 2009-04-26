module Caterpillar #:nodoc:
  # Routes for Portlet Test Bench.
  module Routing
    module MapperExtensions # :nodoc:
      def caterpillar

        @set.add_named_route(
          'portlet_test_bench',
          'caterpillar/test_bench',
          {:controller => 'Caterpillar::Application'})

        @set.add_route(
          'caterpillar/test_bench/:controller/:action')

      end
    end
  end
end