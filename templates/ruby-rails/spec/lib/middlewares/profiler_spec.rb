require "spec_helper"

describe Middlewares::Profiler do
  before(:each) do
    allow(Middlewares::Profiler).to receive(:`).and_return("\nNAME\n")
  end

  describe ".hostname" do
    it "should return the hostname" do
      expect(Middlewares::Profiler.hostname).to eq("NAME")
    end
  end

  describe "#initialize" do
    it "should save the app" do
      subject = Middlewares::Profiler.new("APP")
      expect(subject.instance_variable_get(:@app)).to eq("APP")
    end
  end

  describe "#call" do
    it "should append time information to the response" do
      subject = Middlewares::Profiler.new(->(_) {
        Timecop.freeze(Time.now + 12.34)
        ["OK", {}]
      })

      expect(subject.call("ENV")).to eq(["OK", {"X-Served-By" => "NAME", "X-Response-Time" => "12340.000ms"}])
    end
  end
end
