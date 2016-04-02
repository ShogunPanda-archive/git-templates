json.errors do
  json.child! do
    json.code 500
    json.title "Unexpected Server Error"

    unless Rails.env.production?
      json.message @exception.message
      json.class @exception.class.to_s
      json.backtrace @backtrace if @backtrace
    end
  end
end