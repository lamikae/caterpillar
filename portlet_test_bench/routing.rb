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
          'caterpillar/test_bench/http_methods/:action',
          {:controller => 'Caterpillar::HttpMethods'})

        @set.add_route(
          'caterpillar/test_bench/javascript/:action',
          {:controller => 'Caterpillar::Js'})

        @set.add_route(
          'caterpillar/test_bench/css/:action',
          {:controller => 'Caterpillar::Css'})

        @set.add_route(
          'caterpillar/test_bench/login/:action',
          {:controller => 'Caterpillar::Login'})

        @set.add_route(
          'caterpillar/test_bench/resource/:action',
          {:controller => 'Caterpillar::Resource'})

        @set.add_route(
          'caterpillar/test_bench/session/:action',
          {:controller => 'Caterpillar::Session'})

        @set.add_route(
          'caterpillar/test_bench/user/:action',
          {:controller => 'Caterpillar::User'})

        @set.add_route(
          'caterpillar/test_bench/liferay/:action',
          {:controller => 'Caterpillar::Liferay'})

        # Liferay GID
        @set.add_route(
          'caterpillar/test_bench/liferay/:action/gid/:gid',
          {:controller => 'Caterpillar::Liferay'})

        # xUnit test routes
        @set.add_route(
          'caterpillar/test_bench/junit/:action',
          {:controller => 'Caterpillar::Junit'})

      end
    end
  end
end
