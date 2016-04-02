module Concerns
  module ResponseHandling
    attr_accessor :included

    def response_template_for(record)
      return @object_template if @object_template
      record = record.first if record.respond_to?(:first)
      record.class.name.underscore.gsub("/", "_")
    end

    def response_meta(default = nil)
      @meta || default || HashWithIndifferentAccess.new
    end

    def response_data(default = nil)
      @data || default || HashWithIndifferentAccess.new
    end

    def response_links(default = nil)
      @links || default || HashWithIndifferentAccess.new
    end

    def response_included(default = nil)
      controller.included || default || HashWithIndifferentAccess.new
    end

    def response_include(object, template = nil)
      controller.included ||= {}
      controller.included[sprintf("%s:%s", response_template_for(object), object.to_param)] = [object, template]
      controller.included
    end

    def response_timestamp(timestamp)
      timestamp.safe_send(:strftime, "%FT%T.%L%z")
    end
  end
end
