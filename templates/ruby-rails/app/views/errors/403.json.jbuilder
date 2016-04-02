json.errors do
  json.child! do
    json.code 403
    json.title "Forbidden"
    json.detail @authentication_error[:error]
  end
end