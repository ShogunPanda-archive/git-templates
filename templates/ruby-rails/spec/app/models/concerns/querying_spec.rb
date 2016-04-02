require "spec_helper"

describe Concerns::Querying do
  class MockQueryingModel < ApplicationRecord
    self.table_name = "models"
    SECONDARY_QUERY = "name = :id"

    attr_accessor :handle, :name, :uuid
  end

  class MockQueryingOtherModel < ApplicationRecord
    self.table_name = "models"
  end

  subject {
    MockQueryingModel.new(id: SecureRandom.uuid, handle: "HANDLE", name: "NAME")
  }

  describe ".find_with_any!" do
    it "should find a record using the primary key when the ID is a UUID" do
      expect(MockQueryingOtherModel).to receive(:find).with(subject.id).and_return(subject)
      expect(MockQueryingOtherModel.find_with_any!(subject.id)).to eq(subject)
    end

    it "should find a record using the secondary key" do
      expect(MockQueryingOtherModel).to receive(:find_by!).with(handle: subject.handle).and_return(subject)
      expect(MockQueryingOtherModel.find_with_any!(subject.handle)).to eq(subject)
    end

    it "should find a record using the secondary query" do
      expect(MockQueryingModel).to receive(:find_by!).with("name = :id", {id: subject.name}).and_return(subject)
      expect(MockQueryingModel.find_with_any!(subject.name).id).to eq(subject.id)
    end

    it "should fallback to a reasonable query" do
      expect(MockQueryingOtherModel).to receive(:find_by!).with(handle: subject.handle).and_return(subject)
      expect(MockQueryingOtherModel.find_with_any!(subject.handle).id).to eq(subject.id)
    end

    it "should raise an exception when nothing is found" do
      expect { MockQueryingOtherModel.find_with_any!("NOTHING") }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe ".find_with_any" do
    it "should find a records" do
      expect(MockQueryingOtherModel).to receive(:find_by!).with(handle: subject.handle).and_return(subject)
      expect(MockQueryingOtherModel.find_with_any(subject.handle)).to eq(subject)
    end

    it "should raise an exception when nothing is found" do
      expect { MockQueryingOtherModel.find_with_any("NOTHING") }.not_to raise_error
    end
  end

  describe ".search" do
    let(:params) { {filter: {query: "ABC"}} }
    let(:table_name) { "models" }

    it "should do nothing if no value is present" do
      expect(MockQueryingOtherModel.search().to_sql).to eq("SELECT \"#{table_name}\".* FROM \"#{table_name}\"")
    end

    it "should perform a query on the fields" do
      expect(MockQueryingOtherModel.search(params: params, fields: [:name, :token, :secret]).to_sql).to eq("SELECT \"#{table_name}\".* FROM \"#{table_name}\" WHERE (name ILIKE '%ABC%' OR token ILIKE '%ABC%' OR secret ILIKE '%ABC%')")
    end

    it "should allow prefix based queries" do
      expect(MockQueryingOtherModel.search(params: params, start_only: true).to_sql).to eq("SELECT \"#{table_name}\".* FROM \"#{table_name}\" WHERE (name ILIKE 'ABC%')")
    end

    it "should allow case sensitive searches" do
      expect(MockQueryingOtherModel.search(params: params, case_sensitive: true).to_sql).to eq("SELECT \"#{table_name}\".* FROM \"#{table_name}\" WHERE (name LIKE '%ABC%')")
    end

    it "should allow to use AND based searches" do
      expect(MockQueryingOtherModel.search(params: params, method: :other).to_sql).to eq("SELECT \"#{table_name}\".* FROM \"#{table_name}\" WHERE (name ILIKE '%ABC%')")
    end

    it "should extend existing queries" do
      expect(MockQueryingOtherModel.search(params: params, query: MockQueryingOtherModel.where("secret IS NOT NULL")).to_sql).to eq("SELECT \"#{table_name}\".* FROM \"#{table_name}\" WHERE (secret IS NOT NULL) AND (name ILIKE '%ABC%')")
    end
  end
end