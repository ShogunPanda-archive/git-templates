unless local_assigns[:debug]
  json.errors do
    json.child! do
      json.code response.code
      json.title "Bad Request"
      json.detail @reason || @errors
    end
  end
end