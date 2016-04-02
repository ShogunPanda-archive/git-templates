module Concerns
  module AdditionalValidations
    extend ActiveSupport::Concern

    def additional_errors
      @additional_errors ||= ActiveModel::Errors.new(self)
    end

    def run_validations!
      errors.messages.merge!(additional_errors.messages)
      super
    end

    def all_validation_errors
      additional_errors.each do |field, error|
        errors.add(field, error)
      end

      errors.each do |field|
        errors[field].uniq!
      end

      errors
    end
  end
end
