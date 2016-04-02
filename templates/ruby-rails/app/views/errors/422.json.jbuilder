if @errors.is_a?(Hash)
  errors = @errors.map {|field, errors|
    [field, errors.ensure_array.first]
  }

  json.errors errors do |(field, error)|
    json.code 422
    json.title "Bad Attribute"
    json.field field
    error += "." unless error.end_with?(".")
    json.detail error.capitalize
  end
else
  json.errors @errors.ensure_array do |error|
    json.code 422
    json.title "Unknown Attribute"
    json.field error
  end
end