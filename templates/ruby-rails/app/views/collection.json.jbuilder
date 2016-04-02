json.data @objects do |object|
  object_template = local_assigns.fetch(:model_template, response_template_for(object))
  json.partial! partial: "models/#{object_template}", locals: {object: object}
end