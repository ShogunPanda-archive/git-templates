require "spec_helper"

describe Validators::BaseValidator do
  class BaseMockValidationValidator < Validators::BaseValidator
    def check_valid?(_)
      false
    end
  end

  class BaseMockModel
    include ActiveModel::Validations
    include Concerns::AdditionalValidations

    attr_reader :field, :other_field
    validates :field, "base_mock_validation" => {message: "ERROR"}
    validates :other_field, "base_mock_validation" => {default_message: "DEFAULT", additional: true}
  end

  describe "#validate_each" do
    it "should correctly record messages" do
      subject = BaseMockModel.new
      subject.validate
      expect(subject.errors.to_hash).to eq({field: ["ERROR"]})
      expect(subject.additional_errors.to_hash).to eq({other_field: ["DEFAULT"]})
    end
  end
end

describe Validators::UuidValidator do
  class UUIDMockModel
    include ActiveModel::Validations
    include Concerns::AdditionalValidations

    attr_accessor :field
    validates :field, "validators/uuid" => true
  end

  describe "#validate_each" do
    it "should correctly validate fields" do
      subject = UUIDMockModel.new

      subject.field = "d250e78f-887a-4da2-8b4f-59f61c809bed"
      subject.validate
      expect(subject.errors.to_hash).to eq({})

      subject.field = "100"
      subject.validate
      expect(subject.errors.to_hash).to eq({field: ["must be a valid UUID"]})
    end
  end
end

describe Validators::EmailValidator do
  class EmailMockModel
    include ActiveModel::Validations
    include Concerns::AdditionalValidations

    attr_accessor :field
    validates :field, "validators/email" => true
  end

  describe
  describe "#validate_each" do
    it "should correctly validate fields" do
      subject = EmailMockModel.new
      subject.field = 100
      subject.validate
      expect(subject.errors.to_hash).to eq({field: ["must be a valid email"]})
    end
  end
end

describe Validators::BooleanValidator do
  class BooleanMockModel
    include ActiveModel::Validations
    include Concerns::AdditionalValidations

    attr_accessor :field
    validates :field, "validators/boolean" => true
  end

  describe ".parse" do
    it "should correctly parse a value" do
      expect(Validators::BooleanValidator.parse("YES")).to be_truthy
      expect(Validators::BooleanValidator.parse("OTHER")).to be_falsey
    end

    it "should raise errors if asked to" do
      expect(Validators::BooleanValidator.parse(nil, raise_errors: true)).to be_falsey
      expect { Validators::BooleanValidator.parse("", raise_errors: true) }.to raise_error(ArgumentError, "Invalid boolean value \"\".")
      expect { Validators::BooleanValidator.parse("FOO", raise_errors: true) }.to raise_error(ArgumentError, "Invalid boolean value \"FOO\".")
    end
  end

  describe "#validate_each" do
    it "should correctly validate fields" do
      subject = BooleanMockModel.new
      subject.field = 100
      subject.validate
      expect(subject.errors.to_hash).to eq({field: ["must be a valid truthy/falsey value"]})
    end
  end
end

describe Validators::PhoneValidator do
  class PhoneMockModel
    include ActiveModel::Validations
    include Concerns::AdditionalValidations

    attr_accessor :field
    validates :field, "validators/phone" => true
  end

  describe "#validate_each" do
    it "should correctly validate fields" do
      subject = PhoneMockModel.new

      subject.field = "+1 650-762-4637"
      subject.validate
      expect(subject.errors.to_hash).to eq({})

      subject.field = "FOO"
      subject.validate
      expect(subject.errors.to_hash).to eq({field: ["must be a valid phone"]})
    end
  end
end

describe Validators::ZipCodeValidator do
  class ZipCodeMockModel
    include ActiveModel::Validations
    include Concerns::AdditionalValidations

    attr_accessor :field
    validates :field, "validators/zip_code" => true
  end

  describe "#validate_each" do
    it "should correctly validate fields" do
      subject = ZipCodeMockModel.new

      subject.field = "12345"
      subject.validate
      expect(subject.errors.to_hash).to eq({})

      subject.field = "12345-6789"
      subject.validate
      expect(subject.errors.to_hash).to eq({})


      subject.field = "100"
      subject.validate
      expect(subject.errors.to_hash).to eq({field: ["must be a valid ZIP code"]})
    end
  end
end

describe Validators::TimestampValidator do
  class TimestampMockModel
    include ActiveModel::Validations
    include Concerns::AdditionalValidations

    attr_accessor :field, :other_field
    validates :field, "validators/timestamp" => true
    validates :other_field, "validators/timestamp" => {formats: ["%Y"]}
  end

  describe ".parse" do
    it "should parse respecting formats, using ISO-8601 formats by default" do
      ISO8601 = "%FT%T%z".freeze
      FULL_ISO8601 = "%FT%T.%L%z".freeze

      expect(Validators::TimestampValidator.parse("2016-05-04T03:02:01+06:00")).to eq(DateTime.civil(2016, 5, 4, 3, 2, 1, "+6"))
      expect(Validators::TimestampValidator.parse("2016-05-04T03:02:01.789-05:00")).to eq(DateTime.civil(2016, 5, 4, 3, 2, 1.789, "-5"))
      expect(Validators::TimestampValidator.parse("2016-05-04")).to be_nil
      expect(Validators::TimestampValidator.parse("2016-05-04+06:00", formats: ["%F%z"])).to eq(DateTime.civil(2016, 5, 4, 0, 0, 0, "+6"))
    end

    it "should raise errors if asked to" do
      expect { Validators::TimestampValidator.parse("2016-05-04", raise_errors: true) } .to raise_error(ArgumentError, "Invalid timestamp \"2016-05-04\".")
    end
  end

  describe "#validate_each" do
    it "should correctly validate fields" do
      subject = TimestampMockModel.new
      subject.field = 2016
      subject.other_field = "xxxx"
      subject.validate
      expect(subject.errors.to_hash).to eq({field: ["must be a valid ISO 8601 timestamp"], other_field: ["must be a valid ISO 8601 timestamp"]})

      subject.field = Time.now
      subject.other_field = "2016"
      subject.validate
      expect(subject.errors.to_hash).to eq({})
    end
  end
end

describe Validators::ServiceTypeValidator do
  class ServiceTypeMockModel
    include ActiveModel::Validations
    include Concerns::AdditionalValidations

    attr_accessor :field
    validates :field, "validators/service_type" => true
  end

  describe "#validate_each" do
    it "should correctly validate fields" do
      subject = ServiceTypeMockModel.new

      subject.field = "oil-filter"
      subject.validate
      expect(subject.errors.to_hash).to eq({})

      subject.field = "100"
      subject.validate
      expect(subject.errors.to_hash).to eq({field: ["must be a valid service type"]})
    end
  end
end