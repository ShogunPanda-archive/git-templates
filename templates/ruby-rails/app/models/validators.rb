module Validators
  class BaseValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      checked = check_valid?(value)
      return checked if checked

      message = options[:message] || options[:default_message]
      destination = options[:additional] ? record.additional_errors : record.errors
      destination[attribute] << message
      nil
    end
  end

  class ReferenceValidator < BaseValidator
    def initialize(options)
      @class_name = options[:class_name]
      label = options[:label] || options[:class_name].classify
      super(options.reverse_merge(default_message: "must be a valid #{label} (cannot find a #{label} with id \"%s\")"))
    end

    def validate_each(record, attribute, values)
      values = Serializers::JSON.load(values, false, values)

      values.ensure_array.each do |value|
        checked = @class_name.classify.constantize.find_with_any(value)
        add_failure(attribute, record, value) unless checked
      end
    end

    private

    def add_failure(attribute, record, value)
      message = options[:message] || options[:default_message]
      destination = options[:additional] ? record.additional_errors : record.errors
      destination[attribute] << sprintf(message, value)
    end
  end

  class UuidValidator < BaseValidator
    VALID_REGEX = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i

    def initialize(options)
      super(options.reverse_merge(default_message: "must be a valid UUID"))
    end

    def check_valid?(value)
      value.blank? || value =~ VALID_REGEX
    end
  end

  class EmailValidator < BaseValidator
    def initialize(options)
      super(options.reverse_merge(default_message: "must be a valid email"))
    end

    def check_valid?(value)
      value.blank? || UrlsParser.instance.email?(value.ensure_string)
    end
  end

  class BooleanValidator < BaseValidator
    def self.parse(value, raise_errors: false)
      raise(ArgumentError, "Invalid boolean value \"#{value}\".") if !value.nil? && !value.boolean? && raise_errors
      value.to_boolean
    end

    def initialize(options)
      super(options.reverse_merge(default_message: "must be a valid truthy/falsey value"))
    end

    def check_valid?(value)
      value.blank? || value.boolean?
    end
  end

  class PhoneValidator < BaseValidator
    VALID_REGEX = /^(
      ((\+|00)\d)? # International prefix
      ([0-9\-\s\/\(\)]{7,}) # All the rest
    )$/mx

    def initialize(options)
      super(options.reverse_merge(default_message: "must be a valid phone"))
    end

    def check_valid?(value)
      value.blank? || value =~ VALID_REGEX
    end
  end

  class ZipCodeValidator < BaseValidator
    VALID_REGEX = /^(\d{5}(-\d{1,4})?)$/

    def initialize(options)
      super(options.reverse_merge(default_message: "must be a valid ZIP code"))
    end

    def check_valid?(value)
      value.blank? || value =~ VALID_REGEX
    end
  end

  class TimestampValidator < BaseValidator
    def self.parse(value, formats: nil, raise_errors: false)
      return value if [ActiveSupport::TimeWithZone, DateTime, Date, Time].include?(value.class)

      formats ||= Rails.application.config.timestamp_formats.values.dup

      rv = catch(:valid) do
        formats.each do |format|
          parsed = safe_parse(value, format)

          throw(:valid, parsed) if parsed
        end

        nil
      end

      raise(ArgumentError, "Invalid timestamp \"#{value}\".") if !rv && raise_errors
      rv
    end

    def self.safe_parse(value, format)
      DateTime.strptime(value, format)
    rescue
      nil
    end

    def initialize(options)
      super(options.reverse_merge(default_message: "must be a valid ISO 8601 timestamp"))
    end

    def check_valid?(value)
      value.blank? || TimestampValidator.parse(value, formats: options[:formats])
    end
  end
end