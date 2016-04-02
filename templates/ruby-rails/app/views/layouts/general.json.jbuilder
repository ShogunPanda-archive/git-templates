json.jsonapi do
  json.version "1.0"
end

json.meta do
  json.status response.status
  json.success response.status / 100 == 2 || response.status == 418
  json.debug @debug || local_assigns[:debug] if @debug || local_assigns.key?(:debug)
  json.handler sprintf("%s/%s", controller_name, action_name) unless Rails.env.production?
end

# Meta
meta = response_meta(local_assigns[:meta])
json.meta meta if meta.present?

if @count || @page_size
  json.meta do
    json.total @count
    json.size @page_size || @cursor.size
  end
end

# Data
data = response_data(local_assigns[:data])
json.data data if data.present?

# Template
json.merge! JSON.parse(yield) if block_given? && !local_assigns[:empty]

# Links
links = response_links(local_assigns[:links])
json.links links if links.present?

# Included and pagination
json.partial! "/included"
json.partial! "/pagination" if @objects && !pagination_skip? && pagination_supported?