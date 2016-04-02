require "spec_helper"

describe Concerns::AdditionalValidations do
  class AdditionalValidationsMockModel
    include ActiveModel::Validations
    include Concerns::AdditionalValidations

    attr_reader :field
    validates :field, "presence" => true
  end

  describe "#additional_errors" do
    it "should return a ActiveModel::Errors object" do
      expect(AdditionalValidationsMockModel.new.additional_errors).to be_a(ActiveModel::Errors)
    end
  end

  describe "#run_validations!" do
    it "should merge errors when validating" do
      subject = AdditionalValidationsMockModel.new
      subject.additional_errors.add(:field, "ANOTHER")
      subject.validate
      expect(subject.errors.to_hash).to eq({field: ["ANOTHER", "can't be blank"]})
    end
  end

  describe "#all_validation_errors" do
    it "should allow to add additional errors after validation" do
      subject = AdditionalValidationsMockModel.new
      expect(subject.all_validation_errors.to_hash).to eq({})
      subject.validate
      expect(subject.all_validation_errors.to_hash).to eq({field: ["can't be blank"]})
      subject.additional_errors.add(:field, "ANOTHER")
      expect(subject.all_validation_errors.to_hash).to eq({field: ["can't be blank", "ANOTHER"]})
      expect(subject.all_validation_errors.to_hash).to eq({field: ["can't be blank", "ANOTHER"]}) # Should not add errors twice
    end
  end
end
