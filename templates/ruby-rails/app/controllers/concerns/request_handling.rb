module Concerns
  module RequestHandling
    CONTENT_TYPE = "application/vnd.api+json".freeze

    def request_handle_cors
      headers["Access-Control-Allow-Origin"] = Rails.env.development? ? "http://#{request_source_host}:4200" : Rails.application.secrets.cors_source
      headers["Access-Control-Allow-Methods"] = "POST, GET, PUT, DELETE, OPTIONS"
      headers["Access-Control-Allow-Headers"] = "Content-Type, X-User-Email, X-User-Token"
      headers["Access-Control-Max-Age"] = 1.year.to_i.to_s
    end

    def request_validate
      content_type = request_valid_content_type
      request.format = :json
      response.content_type = content_type unless Rails.env.development? && params["json"]

      @cursor = PaginationCursor.new(params, :page)

      params[:data] ||= HashWithIndifferentAccess.new

      validate_data(content_type)
    end

    def request_source_host
      @api_source ||= URI.parse(request.url).host
    end

    def request_valid_content_type
      Concerns::RequestHandling::CONTENT_TYPE
    end

    def request_extract_model(target, type_field: :type, attributes_field: :attributes, relationships_field: :relationships)
      data = params[:data]

      request_validate_model_type(target, data, type_field)

      data = data[attributes_field]
      fail_request!(:bad_request, "Missing attributes in the \"attributes\" field.") if data.blank?

      # Extract attributes using strong parameters
      data = unembed_relationships(validate_attributes(data, target), target, relationships_field)

      # Extract relationships
      data.merge!(validate_relationships(params[:data], target, relationships_field))

      data
    end

    def request_cast_attributes(target, attributes)
      types = target.class.column_types

      attributes.each do |k, v|
        request_cast_attribute(target, attributes, types, k, v)
      end

      attributes
    end

    private

    def validate_data(content_type)
      if request.post? || request.patch?
        raise(Errors::BadRequestError) unless request.content_type == content_type

        request_load_data
        raise(Errors::MissingDataError) unless params[:data].present?
      end
    end

    def request_load_data
      data_source =
        begin
          request.body.read
        rescue
          nil
        end

      return if data_source.blank?

      data = ActiveSupport::JSON.decode(data_source)
      params[:data] = data.fetch("data", {}).with_indifferent_access
    rescue JSON::ParserError
      raise(Errors::InvalidDataError)
    end

    def request_validate_model_type(target, data, type_field)
      provided_type = data[type_field]
      expected_type = sanitize_model_name(target.class.name)

      return if sanitize_model_name(data[type_field]) == expected_type

      fail_request!(
        :bad_request, "#{provided_type.present? ? "Invalid type \"#{provided_type}\"" : "No type"} provided when type \"#{expected_type}\" was expected."
      )
    end

    def request_cast_attribute(target, attributes, types, key, value)
      case types[key].type
      when :boolean then
        Validators::BooleanValidator.parse(value, raise_errors: true)
        attributes[key] = value.to_boolean
      when :datetime
        value = Validators::TimestampValidator.parse(value, raise_errors: true)
        attributes[key] = value
      end
    rescue => e
      target.additional_errors.add(key, e.message)
    end

    def sanitize_model_name(name)
      name.ensure_string.underscore.singularize
    end

    def validate_attributes(data, target)
      # Before performing the validation, copy all embedded data to a temporary hash and replace with boolean in order to pass validation
      copied = {}

      data.each do |k, v|
        if v.is_a?(Hash)
          copied[k] = v
          data[k] = true
        end
      end

      ActionController::Parameters.new(data).permit(target.class::ATTRIBUTES).merge(copied) # Now return by restoring copied attributes
    rescue ActionController::UnpermittedParameters => e
      e.params.map! { |s| sprintf("attributes.%s", s) }
      raise e
    end

    def unembed_relationships(data, target, field)
      return data unless defined?(target.class::RELATIONSHIPS)
      relationships = target.class::RELATIONSHIPS

      data.each do |k, v|
        k = k.to_sym
        next unless relationships.include?(k)

        params[:data][field] ||= {}
        params[:data][field][k] = {data: {type: sanitize_model_name(relationships[k] || k), id: v}}
        data.delete(k)
      end

      data
    end

    def validate_relationships(data, target, field)
      return {} unless defined?(target.class::RELATIONSHIPS)
      relationships = target.class::RELATIONSHIPS

      allowed = relationships.keys.reduce({}) do |accu, k|
        accu[k] = {data: [:type, :id]}
        accu
      end

      resolve_references(target, relationships, ActionController::Parameters.new(data[field]).permit(allowed))
    rescue ActionController::UnpermittedParameters => e
      e.params.map! { |s| sprintf("%s.%s", field, s) }
      raise e
    end

    def resolve_references(target, relationships, references)
      references.reduce({}) do |accu, (field, data)|
        begin
          expected, id, sanitized, type = prepare_resolution(data, field, relationships)
          accu[field] = validate_reference(expected, id, sanitized, type)
        rescue => e
          raise e if e.is_a?(Lazier::Exceptions::Debug)
          target.additional_errors.add(field, e.message)
        end

        accu
      end
    end

    def validate_reference(expected, id, sanitized, type)
      raise("Relationship does not contain the \"data.type\" attribute") if type.blank?
      raise("Relationship does not contain the \"data.id\" attribute") if id.blank?
      raise("Invalid relationship type \"#{type}\" provided for when type \"#{expected}\" was expected.") unless sanitized == sanitize_model_name(expected)

      reference = expected.classify.constantize.find_with_any(id)
      raise("Refers to a non existing \"#{sanitized}\" resource.") unless reference
      reference
    end

    def prepare_resolution(data, field, relationships)
      type = data.dig(:data, :type)
      id = data.dig(:data, :id)
      expected = sanitize_model_name(relationships[field.to_sym] || field.classify)
      sanitized = sanitize_model_name(type)

      [expected, id, sanitized, type]
    end
  end
end