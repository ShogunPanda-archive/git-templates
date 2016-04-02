require "spec_helper"

describe Concerns::PaginationHandling do
  class PaginationHandlingMockContainer
    include Concerns::PaginationHandling

    attr_reader :cursor

    def initialize(params = {}, field = :page, count_field = :count)
      @cursor = PaginationCursor.new(params, field, count_field)
    end

    def request
      OpenStruct.new(params: {a: 1, b: 2})
    end

    def url_for(params)
      params
    end
  end

  subject { PaginationHandlingMockContainer.new }

  describe "#paginate" do
    context "when NOT using the offset" do
      it "should apply the query" do
        collection = Make
        cursor = JWT.encode({aud: "pagination", sub: {value: "2001-02-03T04:05:06.789+0700", size: 34, direction: "next"}}, Rails.application.secrets.jwt, "HS256")
        subject = PaginationHandlingMockContainer.new({page: cursor})

        expect(collection).to receive(:where).with("created_at > ?", DateTime.civil(2001, 2, 3, 4, 5, 6.789, "+7")).and_return(collection)
        expect(collection).to receive(:limit).with(34).and_return(collection)
        expect(collection).to receive(:order).with("created_at ASC").and_return(collection)

        expect(subject.paginate(collection, sort_field: :created_at, sort_order: :asc)).to eq(collection)
      end
    end

    context "when using the offset" do
      it "should apply the query" do
        collection = []
        cursor = JWT.encode({aud: "pagination", sub: {value: 12, size: 56, use_offset: true, direction: "next"}}, Rails.application.secrets.jwt, "HS256")
        subject = PaginationHandlingMockContainer.new({page: cursor})

        expect(collection).to receive(:offset).with(12).and_return(collection)
        expect(collection).to receive(:limit).with(56).and_return(collection)
        expect(collection).to receive(:order).with("id ASC").and_return(collection)

        expect(subject.paginate(collection, sort_field: :id, sort_order: :asc)).to eq(collection)
      end
    end

    context "when NOT going next" do
      it "should reverse results" do
        collection = []
        cursor = JWT.encode({aud: "pagination", sub: {value: 12, size: 56, use_offset: true, direction: "prev"}}, Rails.application.secrets.jwt, "HS256")
        subject = PaginationHandlingMockContainer.new({page: cursor})

        expect(collection).to receive(:offset).and_return(collection)
        expect(collection).to receive(:limit).and_return(collection)
        expect(collection).to receive(:order).and_return(collection)
        expect(collection).to receive(:reverse_order).and_return(collection)
        expect(collection).to receive(:reverse).and_return(collection)
        expect(subject.paginate(collection, sort_field: :id, sort_order: :asc)).to eq(collection)
      end
    end
  end

  describe "#pagination_field" do
    it "should return the right field" do
      expect(subject.pagination_field).to eq(:handle)

      subject.instance_variable_set(:@pagination_field, :foo)
      expect(subject.pagination_field).to eq(:foo)
    end
  end

  describe "#pagination_skip?" do
    it "should return the right value" do
      expect(subject.pagination_skip?).to be_nil

      subject.instance_variable_set(:@skip_pagination, "FOO")
      expect(subject.pagination_skip?).to eq("FOO")
    end
  end

  describe "#pagination_supported?" do
    it "check whether pagination is supported" do
      expect(subject.pagination_supported?).to be_falsey

      subject.instance_variable_set(:@objects, OpenStruct.new(first: true))
      expect(subject.pagination_supported?).to be_falsey

      subject.instance_variable_set(:@objects, [])
      expect(subject.pagination_supported?).to be_truthy
    end
  end

  describe "#pagination_url" do
    it "should return null when not supported" do
      expect(subject.pagination_url("next")).to be_nil
    end

    it "should return the right URL when supported" do
      subject.instance_variable_set(:@objects, ["FOO"])

      allow(subject.cursor).to receive(:might_exist?).with("prev", ["FOO"]).and_return(true)
      allow(subject.cursor).to receive(:save).with(["FOO"], "prev", field: :handle).and_return("URL")

      expect(subject.pagination_url("prev")).to eq({a: 1, b: 2, only_path: false, page: "URL"})
    end
  end
end