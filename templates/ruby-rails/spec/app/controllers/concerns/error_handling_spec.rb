require "spec_helper"

describe Concerns::ErrorHandling do
  class ErrorHandlingMockContainer
    include Concerns::ErrorHandling

    def request_valid_content_type
      "FOO"
    end
  end

  class ErrorHandlingMockModel
    include ActiveModel::Validations

    attr_reader :field, :other_field
    validates :field, presence: true
    validates :other_field, presence: true

    def self.i18n_scope
      :activerecord
    end
  end

  subject { ErrorHandlingMockContainer.new }

  describe "fail_request!" do
    it "should raise the right exception" do
      expect { subject.fail_request!(1, 2) }.to raise_error(Errors::BaseError)
    end
  end
  
  describe "error_handle_exception" do
    it "should call the right handler" do
      expect(subject).to receive(:error_handle_bad_request)
      subject.error_handle_exception(Errors::BadRequestError.new)

      expect(subject).to receive(:error_handle_invalid_data)
      subject.error_handle_exception(Errors::InvalidDataError.new)

      expect(subject).to receive(:error_handle_others)
      subject.error_handle_exception(RuntimeError.new)
    end
  end
  
  describe "error_handle_general" do
    it "should render the right template" do
      expect(subject).to receive(:render_error).with(401, "FOO")
      subject.error_handle_general(Errors::BaseError.new({status: 401, error: "FOO"}))
    end
  end
  
  describe "error_handle_others" do
    it "should render the right template and store the useful information" do
      err = RuntimeError.new
      allow(err).to receive(:backtrace).and_return(["FOO", Rails.application.rails_root + "/foo", Rails.application.gems_root + "/foo"])

      expect(subject).to receive(:render).with("errors/500", status: :internal_server_error)
      subject.error_handle_others(err)
      expect(subject.instance_variable_get(:@exception)).to be(err)
      expect(subject.instance_variable_get(:@backtrace)).to eq(["FOO", "$RAILS/foo", "$GEMS/foo"])
    end
  end
  
  describe "error_handle_debug" do
    it "should render the right template with the right data" do
      err = Lazier::Exceptions::Debug.new({a: 1, b: 2}.to_json)
      expect(subject).to receive(:render).with("errors/400", status: 418, locals: {debug: {"a" => 1, "b" => 2}})
      subject.error_handle_debug(err)
    end
  end
  
  describe "error_handle_fordidden" do
    it "should render the right template with the right message" do
      expect(subject).to receive(:render).with("errors/403", status: :forbidden).exactly(2)

      subject.error_handle_fordidden(RuntimeError.new("FOO"))
      expect(subject.instance_variable_get(:@authentication_error)).to eq({error: "FOO"})

      subject.error_handle_fordidden(RuntimeError.new(""))
      expect(subject.instance_variable_get(:@authentication_error)).to eq({error: "You don't have access to this resource."})
    end
  end

  describe "error_handle_not_found" do
    it "should render the right template" do
      expect(subject).to receive(:render).with("errors/404", status: :not_found)
      subject.error_handle_not_found
    end
  end
  
  describe "error_handle_bad_request" do
    it "should render the right template with the right reason" do
      expect(subject).to receive(:render).with("errors/400", status: :bad_request)
      subject.error_handle_bad_request
      expect(subject.instance_variable_get(:@reason)).to eq("Invalid Content-Type specified. Please use \"FOO\" when performing write operations.")
    end
  end
  
  describe "error_handle_missing_data" do
    it "should render the right template with the right reason" do
      expect(subject).to receive(:render).with("errors/400", status: :bad_request)
      subject.error_handle_missing_data
      expect(subject.instance_variable_get(:@reason)).to eq("Missing data.")
    end
  end
  
  describe "error_handle_invalid_data" do
    it "should render the right template with the right reason" do
      expect(subject).to receive(:render).with("errors/400", status: :bad_request)
      subject.error_handle_invalid_data
      expect(subject.instance_variable_get(:@reason)).to eq("Invalid data provided.")
    end
  end
  
  describe "error_handle_unknown_attribute" do
    it "should render the right template with the right errors" do
      object = ErrorHandlingMockModel.new

      expect(subject).to receive(:render).with("errors/422", status: :unprocessable_entity).exactly(2)
      subject.error_handle_unknown_attribute(ActionController::UnpermittedParameters.new(["A", "B"]))
      expect(subject.instance_variable_get(:@errors)).to eq(["A", "B"])

      subject.error_handle_unknown_attribute(ActiveRecord::UnknownAttributeError.new(object, "C"))
      expect(subject.instance_variable_get(:@errors)).to eq("C")
    end
  end
  
  describe "error_handle_validation" do
    it "should render the right template with the right errors" do
      object = ErrorHandlingMockModel.new
      object.validate

      expect(subject).to receive(:render).with("errors/422", status: :unprocessable_entity)
      subject.error_handle_validation(ActiveRecord::RecordInvalid.new(object))
      expect(subject.instance_variable_get(:@errors)).to eq({field: ["can't be blank"], other_field: ["can't be blank"]})
    end
  end
end