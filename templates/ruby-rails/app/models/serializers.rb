module Serializers
  class List
    def self.load(data)
      return data if data.is_a?(Array)
      data.ensure_string.tokenize
    end

    def self.dump(data)
      data.ensure_array.compact.map(&:to_s).join(",")
    end
  end

  class JSON
    def self.load(data, raise_errors = false, default = {})
      data = ActiveSupport::JSON.decode(data)
      data = data.with_indifferent_access if data.is_a?(Hash)
      data
    rescue => e
      raise(e) if raise_errors
      default
    end

    def self.dump(data)
      ActiveSupport::JSON.encode(data.as_json)
    end
  end

  class JWT
    def self.load(serialized, raise_errors = false, default = {})
      data = ::JWT.decode(serialized, Rails.application.secrets.jwt, true, {algorithm: "HS256", verify_aud: true, aud: "data"}).dig(0, "sub")
      data = data.with_indifferent_access if data.is_a?(Hash)
      data
    rescue => e
      raise(e) if raise_errors
      default
    end

    def self.dump(data)
      ::JWT.encode({aud: "data", sub: data.as_json}, Rails.application.secrets.jwt, "HS256")
    end
  end
end
