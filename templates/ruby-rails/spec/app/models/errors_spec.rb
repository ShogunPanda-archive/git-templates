require "spec_helper"

describe Errors::BaseError do
  it "should save details" do
    subject = Errors::BaseError.new({a: 1})
    expect(subject.message).to eq("")
    expect(subject.details).to eq({a: 1})
  end
end
