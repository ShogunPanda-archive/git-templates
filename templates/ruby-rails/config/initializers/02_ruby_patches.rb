Lazier::I18n.default_locale = "en"
Lazier.load!

[ActiveSupport::TimeWithZone, DateTime, Date, Time].each do |klass|
  klass.class_eval do
    def serialize(format = :default)
      self.strftime(Rails.application.config.timestamp_formats.fetch(format))
    end
  end
end