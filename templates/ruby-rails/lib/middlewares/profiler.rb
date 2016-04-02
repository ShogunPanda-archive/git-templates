module Middlewares
  class Profiler
    def self.hostname
      @hostname ||= `hostname`.strip
    end

    def initialize(app)
      @app = app
    end

    def call(env)
      start = Time.now.to_f

      res = @app.call(env)
      res[1]["X-Served-By"] = Profiler.hostname
      res[1]["X-Response-Time"] = sprintf("%0.3fms", (Time.now.to_f - start) * 1000)

      res
    end
  end
end
