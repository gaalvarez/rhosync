module Rhosync
  module Stats
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        if Rhosync.stats || Rhosync::Server.stats
          start = Time.now.to_f
          status, headers, body = @app.call(env)
          finish = Time.now.to_f
          metric = "http:#{env['REQUEST_METHOD']}:#{env['PATH_INFO']}"
          source_name = env['rack.request.query_hash']["source_name"] if env['rack.request.query_hash']
          metric << ":#{source_name}" if source_name
          Record.save_average(metric,finish - start)
          [status, headers, body]
        else
          status, headers, body = @app.call(env)
          [status, headers, body]
        end
      end
    end
  end
end