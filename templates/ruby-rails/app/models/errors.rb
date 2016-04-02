module Errors
  class BaseError < RuntimeError
    attr_reader :details

    def initialize(details = nil)
      super("")
      @details = details
    end
  end

  class BadRequestError < BaseError
  end

  class InvalidDataError < BaseError
  end

  class MissingDataError < BaseError
  end

  class AuthenticationError < RuntimeError
  end
end
