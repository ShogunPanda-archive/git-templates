require "spec_helper"

describe Concerns::RequestHandling do
  class RequestHandlingMockContainer
    include Concerns::RequestHandling

    attr_reader :request, :response, :params, :headers

    def initialize(request = nil, params = nil)
      @request = OpenStruct.new(request || {format: nil, url: "", body: "FOO"})
      @response ||= OpenStruct.new({content_type: :html})
      @params = params || HashWithIndifferentAccess.new
      @headers = HashWithIndifferentAccess.new
    end
  end

  subject { RequestHandlingMockContainer.new }

  describe "#request_handle_cors" do
    it "should set the right headers" do
      allow(subject).to receive(:request_source_host).and_return("FOO")

      subject.request_handle_cors
      expect(subject.headers).to eq({
        "Access-Control-Allow-Headers" => "Content-Type, X-User-Email, X-User-Token",
        "Access-Control-Allow-Methods" => "POST, GET, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Origin" => "http://localhost:3000",
        "Access-Control-Max-Age" => "31557600"
      })
    end
  end

  describe "#request_validate" do
    it "should override the request format and the response content type, then prepare the data" do
      subject.request_validate

      expect(subject.request.format).to eq(:json)
      expect(subject.response.content_type).to eq("application/vnd.api+json")
      expect(subject.params[:data]).to be_a(HashWithIndifferentAccess)
    end

    it "should complain when the provided content_type is wrong" do
      allow(subject.request).to receive(:post?).and_return(true)
      allow(subject.request).to receive(:content_type).and_return("FOO")

      expect { subject.request_validate }.to raise_error(Errors::BadRequestError)
    end

    it "should complain when the data is missing" do
      allow(subject.request).to receive(:post?).and_return(true)
      allow(subject.request).to receive(:content_type).and_return(Concerns::RequestHandling::CONTENT_TYPE)

      expect { subject.request_validate }.to raise_error(Errors::MissingDataError)
    end

    it "should complain when the data is not a valid JSON" do
      subject.request.body = OpenStruct.new(read: "FOO")
      allow(subject.request).to receive(:post?).and_return(true)
      allow(subject.request).to receive(:content_type).and_return(Concerns::RequestHandling::CONTENT_TYPE)

      expect { subject.request_validate }.to raise_error(Errors::InvalidDataError)
    end

    it "should complain when the data is missing in the data attribute for JSON API requests" do
      subject.request.body = OpenStruct.new(read: {a: 1}.to_json)
      allow(subject.request).to receive(:post?).and_return(true)
      allow(subject.request).to receive(:content_type).and_return(Concerns::RequestHandling::CONTENT_TYPE)

      expect { subject.request_validate }.to raise_error(Errors::MissingDataError)
    end
  end

  describe "#request_source_host" do
    it "should return the right host" do
      subject.request.url = "http://abc.google.it:1234"
      expect(subject.request_source_host).to eq("abc.google.it")
    end
  end

  describe "#request_valid_content_type" do
    it "should return the right type" do
      expect(subject.request_valid_content_type).to eq("application/vnd.api+json")
    end
  end

  describe "#request_extract_model" do
    before(:each) do
      allow(subject.request).to receive(:post?).and_return(true)
      allow(subject.request).to receive(:content_type).and_return(Concerns::RequestHandling::CONTENT_TYPE)
    end

    it "should complain if the type is missing in the data" do
      subject.request.body = OpenStruct.new(read: {data: {foo: 1, body: 1}}.to_json)
      subject.request_validate

      expect(subject).to receive(:fail_request!).with(:bad_request, "No type provided when type \"update_notification\" was expected.").and_raise(RuntimeError)
      expect { subject.request_extract_model(UpdateNotification.new) }.to raise_error(RuntimeError)
    end

    it "should complain if the type is wrong in the data" do
      subject.request.body = OpenStruct.new(read: {data: {type: "foo", foo: 1, body: 1}}.to_json)
      subject.request_validate

      expect(subject).to receive(:fail_request!).with(:bad_request, "Invalid type \"foo\" provided when type \"update_notification\" was expected.").and_raise(RuntimeError)
      expect { subject.request_extract_model(UpdateNotification.new) }.to raise_error(RuntimeError)
    end

    it "should complain if the data is not inside the attributes field" do
      subject.request.body = OpenStruct.new(read: {data: {type: "update_notification", foo: 1, body: 1}}.to_json)
      subject.request_validate

      expect(subject).to receive(:fail_request!).with(:bad_request, "Missing attributes in the \"attributes\" field.").and_raise(RuntimeError)
      expect { subject.request_extract_model(UpdateNotification.new) }.to raise_error(RuntimeError)
    end

    it "should complain if any unknown attribute is present for the update_notification" do
      subject.request.body = OpenStruct.new(read: {data: {type: "update_notification", attributes: {foo: 1, body: 1}}}.to_json)
      subject.request_validate

      expect { subject.request_extract_model(UpdateNotification.new) }.to raise_error(ActionController::UnpermittedParameters) do |error|
        expect(error.params).to eq(["attributes.foo"])
      end
    end

    it "should allowed hash attributes" do
      subject.request.body = OpenStruct.new(read: {data: {type: "update_notification", attributes: {foo: 1, body: {a: 1}}}}.to_json)
      subject.request_validate

      expect { subject.request_extract_model(UpdateNotification.new) }.to raise_error(ActionController::UnpermittedParameters) do |error|
        expect(error.params).to eq(["attributes.foo"])
      end
    end

    it "should return attributes for the update_notification" do
      subject.request.body = OpenStruct.new(read: {data: {type: "update_notification", attributes: {email: "1", zip: 1}}}.to_json)
      subject.request_validate

      expect(subject.request_extract_model(UpdateNotification.new)).to eq({email: "1", zip: 1}.with_indifferent_access)
    end
  end

  describe "#request_cast_attributes" do
    it "should correctly cast attributes for a update_notification" do
      attributes = {id: 3, created_at: "2001-02-03T04:05:06.789+0700"}.with_indifferent_access
      casted_attributes = {id: 3, created_at: DateTime.civil(2001, 2, 3, 4, 5, 6.789, "+7")}.with_indifferent_access
      expect(subject.request_cast_attributes(UpdateNotification.new, attributes)).to eq(casted_attributes)
    end

    it "should add casting errors to the update_notification validation errors" do
      attributes = {id: 3, is_tracked: "yes", created_at: "NO"}.with_indifferent_access
      object = UpdateNotification.new
      subject.request_cast_attributes(object, attributes)
      expect(object.additional_errors.to_hash).to eq(created_at: ["Invalid timestamp \"NO\"."])
    end
  end
end