Rails.application.routes.draw do
  # Ping
  start_time = Time.now.to_f
  get("ping", to: ->(_){ [200, {"Content-Type" => "text/plain", "X-Up-Time" => sprintf("%0.3fms", (Time.now.to_f - start_time) * 1000)}, ["pong"]] })

  # This is to enable AJAX cross domain
  match '*path', to: 'application#handle_cors', via: :options

  # Insert your routes here

  # Catch alls
  match("/*unused", via: :all, to: "application#error_handle_not_found")
  root(to: "application#error_handle_not_found")
end
