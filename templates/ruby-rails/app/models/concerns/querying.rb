module Concerns
  module Querying
    extend ActiveSupport::Concern

    class_methods do
      def find_with_any!(id)
        if id =~ Validators::UuidValidator::VALID_REGEX
          find(id)
        elsif defined?(self::SECONDARY_KEY)
          find_by!(self::SECONDARY_KEY => id)
        elsif defined?(self::SECONDARY_QUERY)
          find_by!(self::SECONDARY_QUERY, {id: id})
        else
          find_by!(handle: id)
        end
      end

      def find_with_any(id)
        find_with_any!(id)
      rescue ActiveRecord::RecordNotFound
        nil
      end

      def search(params: {}, query: nil, fields: ["name"], start_only: false, parameter: nil, placeholder: :query, method: :or, case_sensitive: false)
        query ||= self.where({})
        value = parameter ? params[parameter] : params.dig(:filter, :query)
        return query if value.blank?

        value = "#{value}%"
        value = "%#{value}" unless start_only

        method = method == :or ? " OR " : " AND "
        operator = case_sensitive ? "LIKE" : "ILIKE"

        sql = fields.map {|f| "#{f} #{operator} :#{placeholder}" }.join(method)
        query.where(sql, {placeholder => value})
      end
    end
  end
end