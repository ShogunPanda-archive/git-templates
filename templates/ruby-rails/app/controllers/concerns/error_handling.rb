module Concerns
  module ErrorHandling
    ERROR_HANDLERS = {
      "ActiveRecord::RecordNotFound" => :error_handle_not_found,
      "Errors::AuthenticationError" => :error_handle_fordidden,
      "Errors::InvalidModelError" => :error_handle_invalid_source,
      "Errors::BadRequestError" => :error_handle_bad_request,
      "Errors::MissingDataError" => :error_handle_missing_data,
      "Errors::InvalidDataError" => :error_handle_invalid_data,
      "JSON::ParserError" => :error_handle_invalid_data,
      "ActiveRecord::RecordInvalid" => :error_handle_validation,
      "ActiveRecord::UnknownAttributeError" => :error_handle_unknown_attribute,
      "ActionController::UnpermittedParameters" => :error_handle_unknown_attribute,
      "Errors::BaseError" => :error_handle_general,
      "Lazier::Exceptions::Debug" => :error_handle_debug
    }.freeze

    def fail_request!(status, error)
      raise(Errors::BaseError, {status: status, error: error})
    end

    def error_handle_exception(exception)
      handler = ERROR_HANDLERS.fetch(exception.class.to_s, :error_handle_others)
      send(handler, exception)
    end

    def error_handle_general(exception)
      render_error(exception.details[:status], exception.details[:error])
    end

    def error_handle_others(exception)
      @exception = exception
      @backtrace = exception.backtrace
         .slice(0, 50).map { |line| line.gsub(Rails.application.rails_root, "$RAILS").gsub(Rails.application.gems_root, "$GEMS") }
      render("errors/500", status: :internal_server_error)
    end

    def error_handle_debug(exception)
      render("errors/400", status: 418, locals: {debug: YAML.load(exception.message)})
    end

    def error_handle_fordidden(exception)
      @authentication_error = {error: exception.message.present? ? exception.message : "You don't have access to this resource."}
      render("errors/403", status: :forbidden)
    end

    def error_handle_not_found(_ = nil)
      render("errors/404", status: :not_found)
    end

    def error_handle_bad_request(_ = nil)
      @reason = "Invalid Content-Type specified. Please use \"#{request_valid_content_type}\" when performing write operations."
      render("errors/400", status: :bad_request)
    end

    def error_handle_missing_data(_ = nil)
      @reason = "Missing data."
      render("errors/400", status: :bad_request)
    end

    def error_handle_invalid_data(_ = nil)
      @reason = "Invalid data provided."
      render("errors/400", status: :bad_request)
    end

    def error_handle_unknown_attribute(exception)
      @errors = exception.is_a?(ActionController::UnpermittedParameters) ? exception.params : exception.attribute
      render("errors/422", status: :unprocessable_entity)
    end

    def error_handle_validation(exception)
      @errors = exception.record.errors.to_hash
      render("errors/422", status: :unprocessable_entity)
    end
  end
end