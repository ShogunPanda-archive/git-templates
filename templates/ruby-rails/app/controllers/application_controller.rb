# To use Rails API, replace ActionController::Base with ActionController::API and then include ActionView::Layouts
class ApplicationController < ActionController::Base
  include Concerns::RequestHandling
  include Concerns::ResponseHandling
  include Concerns::PaginationHandling
  include Concerns::ErrorHandling
  helper Concerns::ResponseHandling
  helper Concerns::PaginationHandling

  layout "general"
  before_filter :request_handle_cors
  before_filter :request_validate

  attr_reader :current_account, :cursor, :request_cursor

  # Exception handling
  rescue_from Exception, with: :error_handle_exception
  # This allows to avoid to declare all the views
  rescue_from ActionView::MissingTemplate, with: :render_default_views

  def default_url_options
    rv = {only_path: false}
    rv = {host: request_source_host} if Rails.env.development?
    rv
  end

  def handle_cors
    render(nothing: true, status: :no_content)
  end

  def render_error(status, errors)
    @errors = errors
    status_code = status.is_a?(Fixnum) ? status : Rack::Utils::SYMBOL_TO_STATUS_CODE.fetch(status.to_sym, 500)
    render("errors/#{status_code}", status: status)
  end

  private

  def render_default_views(exception)
    if defined?(@objects)
      render "/collection"
    elsif defined?(@object)
      render "/object"
    else
      error_handle_exception(exception)
    end
  end
end
