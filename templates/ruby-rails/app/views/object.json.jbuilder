json.data do
  record_template = local_assigns.fetch(:model_template, response_template_for(@object))
  json.partial! "models/#{record_template}", locals: {object: @object}
end
