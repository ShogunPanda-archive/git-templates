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

    def fail_request!(status, error)
      raise(Errors::BaseError, {status: status, error: error})
    end
  end

  FirstMockModel = Struct.new(:id)

  class SecondMockModel
  end

  class MockModel
    include ActiveModel::Model
    include Concerns::AdditionalValidations

    ATTRIBUTES = [:id, :other, :created_at, :first_mock_model]
    RELATIONSHIPS = {first_mock_model: nil, second: SecondMockModel}

    def self.column_types
      {"id" =>  OpenStruct.new(type: :string), "other" => OpenStruct.new(type: :boolean), "created_at" => OpenStruct.new(type: :datetime)}
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

      expect(subject).to receive(:fail_request!).with(:bad_request, "No type provided when type \"mock_model\" was expected.").and_raise(RuntimeError)
      expect { subject.request_extract_model(MockModel.new) }.to raise_error(RuntimeError)
    end

    it "should complain if the type is wrong in the data" do
      subject.request.body = OpenStruct.new(read: {data: {type: "foo", foo: 1, body: 1}}.to_json)
      subject.request_validate

      expect(subject).to receive(:fail_request!).with(:bad_request, "Invalid type \"foo\" provided when type \"mock_model\" was expected.").and_raise(RuntimeError)
      expect { subject.request_extract_model(MockModel.new) }.to raise_error(RuntimeError)
    end

    it "should complain if the data is not inside the attributes field" do
      subject.request.body = OpenStruct.new(read: {data: {type: "mock_model", foo: 1, body: 1}}.to_json)
      subject.request_validate

      expect(subject).to receive(:fail_request!).with(:bad_request, "Missing attributes in the \"attributes\" field.").and_raise(RuntimeError)
      expect { subject.request_extract_model(MockModel.new) }.to raise_error(RuntimeError)
    end

    it "should complain if any unknown attribute is present for the mock_model" do
      subject.request.body = OpenStruct.new(read: {data: {type: "mock_model", attributes: {foo: 1, other: 1}}}.to_json)
      subject.request_validate

      expect { subject.request_extract_model(MockModel.new) }.to raise_error(ActionController::UnpermittedParameters) do |error|
        expect(error.params).to eq(["attributes.foo"])
      end
    end

    it "should allowed hash attributes" do
      subject.request.body = OpenStruct.new(read: {data: {type: "mock_model", attributes: {foo: 1, other: {a: 1}}}}.to_json)
      subject.request_validate

      expect { subject.request_extract_model(MockModel.new) }.to raise_error(ActionController::UnpermittedParameters) do |error|
        expect(error.params).to eq(["attributes.foo"])
      end
    end

    it "should return attributes for the mock_model" do
      subject.request.body = OpenStruct.new(read: {data: {type: "mock_model", attributes: {id: "1", other: 1}}}.to_json)
      subject.request_validate

      expect(subject.request_extract_model(MockModel.new)).to eq({id: "1", other: 1}.with_indifferent_access)
    end

    it "should return relationships for the model" do
      first = FirstMockModel.new(1)
      allow(FirstMockModel).to receive(:find_with_any).and_return(first)
      subject.request.body = OpenStruct.new(read: {data: {type: "mock_model", attributes: {id: 1}, relationships: {first_mock_model: {data: {type: "first_mock_model", id: first.id}}}}}.to_json)
      subject.request_validate

      expect(subject.request_extract_model(MockModel.new)).to eq({id: 1, first_mock_model: first}.with_indifferent_access)
    end

    it "should move inline references to the relationship objects" do
      first = FirstMockModel.new(1)
      allow(FirstMockModel).to receive(:find_with_any).and_return(first)
      subject.request.body = OpenStruct.new(read: {data: {type: "mock_model", attributes: {id: 1, first_mock_model: first.id}}}.to_json)
      subject.request_validate

      extracted = subject.request_extract_model(MockModel.new)
      expect(extracted.keys.map(&:to_sym)).to eq([:id, :first_mock_model])
      expect(extracted[:first_mock_model].id).to eq(first.id)
    end

    it "should reject unallowed relationships" do
      subject.request.body = OpenStruct.new(read: {data: {type: "mock_model", attributes: {id: 1}, relationships: {another: {}}}}.to_json)
      subject.request_validate

      target = MockModel.new
      expect { subject.request_extract_model(target) }.to raise_error(ActionController::UnpermittedParameters) do |error|
        expect(error.params).to eq(["relationships.another"])
      end
    end

    it "should reject malformed relationships" do
      first = FirstMockModel.new(1)

      target = MockModel.new
      subject.request.body = OpenStruct.new(read: {data: {type: "mock_model", attributes: {id: 1}, relationships: {first_mock_model: {data: {id: first.id}}}}}.to_json)
      subject.request_validate
      subject.request_extract_model(target)
      expect(target.additional_errors.to_hash).to eq({first_mock_model: ["Relationship does not contain the \"data.type\" attribute"]})

      target = MockModel.new
      subject.request.body = OpenStruct.new(read: {data: {type: "mock_model", attributes: {id: 1}, relationships: {first_mock_model: {data: {type: "first_mock_model"}}}}}.to_json)
      subject.request_validate
      subject.request_extract_model(target)
      expect(target.additional_errors.to_hash).to eq({first_mock_model: ["Relationship does not contain the \"data.id\" attribute"]})

      target = MockModel.new
      subject.request.body = OpenStruct.new(read: {data: {type: "mock_model", attributes: {id: 1}, relationships: {first_mock_model: {data: {type: "foo", id: 1}}}}}.to_json)
      subject.request_validate
      subject.request_extract_model(target)
      expect(target.additional_errors.to_hash).to eq({first_mock_model: ["Invalid relationship type \"foo\" provided for when type \"first_mock_model\" was expected."]})
    end

    it "should reject invalid relationships" do
      allow(SecondMockModel).to receive(:find_with_any).and_return(false)
      target = MockModel.new
      subject.request.body = OpenStruct.new(read: {data: {type: "mock_model", attributes: {id: 1}, relationships: {second: {data: {type: "second_mock_model", id: -1}}}}}.to_json)
      subject.request_validate
      subject.request_extract_model(target)
      expect(target.additional_errors.to_hash).to eq({second: ["Refers to a non existing \"second_mock_model\" resource."]})
    end
  end

  describe "#request_cast_attributes" do
    it "should correctly cast attributes for a mock_model" do
      attributes = {id: 3, other: "YES", created_at: "2001-02-03T04:05:06.789+0700"}.with_indifferent_access
      casted_attributes = {id: 3, other: true, created_at: DateTime.civil(2001, 2, 3, 4, 5, 6.789, "+7")}.with_indifferent_access
      expect(subject.request_cast_attributes(MockModel.new, attributes)).to eq(casted_attributes)
    end

    it "should add casting errors to the mock_model validation errors" do
      attributes = {id: 3, other: "yes", created_at: "NO"}.with_indifferent_access
      object = MockModel.new
      subject.request_cast_attributes(object, attributes)
      expect(object.additional_errors.to_hash).to eq(created_at: ["Invalid timestamp \"NO\"."])
    end
  end
end