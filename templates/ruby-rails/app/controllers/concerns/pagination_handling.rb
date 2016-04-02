module Concerns
  module PaginationHandling
    def paginate(collection, sort_field: :id, sort_order: :desc)
      direction = @cursor.direction
      value = @cursor.value

      # Apply the query
      collection = apply_value(collection, value, sort_field, sort_order)
      collection = collection.limit(@cursor.size).order(sprintf("%s %s", sort_field, sort_order.upcase))

      # If we're fetching previous we reverse the order to make sure we fetch the results adiacents to the previous request,
      # then we reverse results to ensure the order requested
      if direction != "next"
        collection = collection.reverse_order
        collection = collection.reverse
      end

      collection
    end

    def pagination_field
      @pagination_field ||= :handle
    end

    def pagination_skip?
      @skip_pagination
    end

    def pagination_supported?
      @objects.respond_to?(:first) && @objects.respond_to?(:last)
    end

    def pagination_url(key = nil)
      exist = @cursor.might_exist?(key, @objects)
      exist ? url_for(request.params.merge(page: @cursor.save(@objects, key, field: pagination_field)).merge(only_path: false)) : nil
    end

    private

    def apply_value(collection, value, sort_field, sort_order)
      if value
        if cursor.use_offset
          collection = collection.offset(value)
        else
          value = DateTime.parse(value, PaginationCursor::TIMESTAMP_FORMAT) if collection.columns_hash[sort_field.to_s].type == :datetime
          collection = collection.where(sprintf("%s %s ?", sort_field, @cursor.operator(sort_order)), value)
        end
      end

      collection
    end
  end
end
