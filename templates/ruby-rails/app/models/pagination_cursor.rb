class PaginationCursor
  DEFAULT_SIZE = 25
  TIMESTAMP_FORMAT = "%FT%T.%6N%z".freeze

  attr_reader :value, :use_offset, :direction, :size

  def initialize(params = {}, field = :page, count_field = :count)
    begin
      payload = JWT.decode(params[field], Rails.application.secrets.jwt, true, {algorithm: "HS256", verify_aud: true, aud: "pagination"}).dig(0, "sub")

      extract_payload(payload)
    rescue
      default_payload
    end

    # Sanitization
    sanitize(count_field, params)
  end

  def operator(order)
    if direction == "next"
      order == :asc ? ">" : "<" # Descending order means newer results first
    else
      order == :asc ? "<" : ">" # Descending order means newer results first
    end
  end

  def might_exist?(type, collection)
    case type.ensure_string
    when "first" then true
    when "next" then collection.present?
    else value.present? && collection.present? # Previous
    end
  end

  def save(collection, type, field: :id, size: nil, use_offset: nil)
    size ||= self.size
    use_offset = self.use_offset if use_offset.nil?
    direction, value = use_offset ? update_with_offset(type, size) : update_with_field(type, collection, field)

    value = value.strftime(TIMESTAMP_FORMAT) if value.respond_to?(:strftime)

    JWT.encode(
      {aud: "pagination", sub: {value: value, use_offset: use_offset, direction: direction, size: size}},
      Rails.application.secrets.jwt, "HS256"
    )
  end
  alias_method :serialize, :save

  private

  def default_payload
    @value = nil
    @direction = "next"
    @size = 0
    @use_offset = false
  end

  def extract_payload(payload)
    @value = payload["value"]
    @direction = payload["direction"]
    @size = payload["size"]
    @use_offset = payload["use_offset"]
  end

  def sanitize(count_field, params)
    @direction = "next" unless ["prev", "previous"].include?(@direction)
    @size = params[count_field].to_integer if params[count_field].present?
    @size = DEFAULT_SIZE if @size < 1
  end

  def update_with_field(type, collection, field)
    case type.ensure_string
    when "next"
      direction = "next"
      value = collection.last&.send(field)
    when "prev", "previous"
      direction = "previous"
      value = collection.first&.send(field)
    else # first
      direction = "next"
      value = nil
    end

    [direction, value]
  end

  def update_with_offset(type, size)
    case type.ensure_string
    when "next"
      direction = "next"
      value = self.value + size
    when "prev", "previous"
      direction = "previous"
      value = [0, self.value - size].max
    else # first
      direction = "next"
      value = nil
    end

    [direction, value]
  end
end
