next_url = pagination_url(:next)
prev_url = pagination_url(:prev)
first_url = pagination_url(:first)

json.links do
  json.next next_url if next_url
  json.prev prev_url if prev_url
  json.first first_url if first_url
end