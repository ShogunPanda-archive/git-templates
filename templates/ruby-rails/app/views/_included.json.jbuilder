included = response_included(local_assigns[:included])

if included.present?
  json.included(included.values) do |(resource, template)|
    template ||= resource.class.to_s.underscore.singularize

    json.partial!("models/#{template}", locals: {object: resource, included: true}) if resource
  end
end