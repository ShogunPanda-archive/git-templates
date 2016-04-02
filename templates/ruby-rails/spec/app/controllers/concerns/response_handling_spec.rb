require "spec_helper"

describe Concerns::ResponseHandling do
  class ResponseHandlingMockContainer
    include Concerns::ResponseHandling
  end

  subject { ResponseHandlingMockContainer.new }

  describe "#response_template_for" do
    it "should return the right template" do
      expect(subject.response_template_for(Resources::MakesController.new)).to eq("resources_makes_controller")
      expect(subject.response_template_for([Resources::MakesController.new])).to eq("resources_makes_controller")
    end
  end

  describe "#response_meta" do
    it "should return the right meta" do
      expect(subject.response_meta).to be_a(HashWithIndifferentAccess)
      expect(subject.response_meta("FOO")).to eq("FOO")

      subject.instance_variable_set(:@meta, "BAR")
      expect(subject.response_meta).to eq("BAR")
    end

  end

  describe "#response_data" do
    it "should return the right data" do
      expect(subject.response_data).to be_a(HashWithIndifferentAccess)
      expect(subject.response_data("FOO")).to eq("FOO")

      subject.instance_variable_set(:@data, "BAR")
      expect(subject.response_data).to eq("BAR")
    end
  end

  describe "#response_timestamp" do
    it "should return the right timestamp" do
      expect(subject.response_timestamp(DateTime.civil(2024, 12, 6, 3, 2, 1, "+7"))).to eq("2024-12-06T03:02:01.000+0700")
    end
  end
end