json.errors do
  json.child! do
    json.code 501
    json.title "Not Implemented"
    json.detail "Unsupported Request."
  end
end