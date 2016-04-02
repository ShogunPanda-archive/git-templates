require "spec_helper"

describe PaginationCursor do
  def create_cursor(value = nil, direction = "next", count = nil, use_offset = false)
    PaginationCursor.new({count: count, page: JWT.encode({aud: "pagination", sub: {value: value, use_offset: use_offset, direction: direction}}, Rails.application.secrets.jwt, "HS256")})
  end

  def decode_cursor(cursor)
    JWT.decode(cursor, Rails.application.secrets.jwt, true, {algorithm: "HS256", verify_aud: true, aud: "pagination"}).dig(0, "sub")
  end

  describe "#initialize" do
    it "should load a JWT token from data" do
      subject = create_cursor("1", "previous", 3, true)

      expect(subject.value).to eq("1")
      expect(subject.direction).to eq("previous")
      expect(subject.size).to eq(3)
      expect(subject.use_offset).to be_truthy
    end

    it "should ensure good defaults" do
      subject = PaginationCursor.new({count: 3, page: "FOO"})

      expect(subject.value).to be_nil
      expect(subject.direction).to eq("next")
      expect(subject.size).to eq(3)
      expect(subject.use_offset).to be_falsey

    end

    it "should sanitize values" do
      subject = create_cursor("1", "other", -1)

      expect(subject.direction).to eq("next")
      expect(subject.size).to eq(PaginationCursor::DEFAULT_SIZE)
    end
  end
  
  describe "#operator" do
    it "should return the right operator" do
      subject = create_cursor("", "next", -1)
      expect(subject.operator(:asc)).to eq(">")
      expect(subject.operator(:desc)).to eq("<")

      subject = create_cursor("", "previous", -1)
      expect(subject.operator(:asc)).to eq("<")
      expect(subject.operator(:desc)).to eq(">")
    end
  end

  describe "#might_exist?" do
    it "should check if a pagination link might exist" do
      subject = create_cursor("", "next", -1)
      expect(subject.might_exist?("first", [])).to be_truthy
      expect(subject.might_exist?("next", [])).to be_falsey
      expect(subject.might_exist?("prev", [])).to be_falsey
      expect(subject.might_exist?("first", [1])).to be_truthy
      expect(subject.might_exist?("next", [1])).to be_truthy
      expect(subject.might_exist?("prev", [1])).to be_falsey

      subject = create_cursor("1", "next", -1)
      expect(subject.might_exist?("prev", [1])).to be_truthy
    end
  end

  describe "#save" do
    describe "when NOT using offset based pagination" do
      it "should generate a valid token for direction next" do
        cursor = create_cursor(1, "next", -1).save([OpenStruct.new(id: 1), OpenStruct.new(id: 2)], "next")
        subject = decode_cursor(cursor)
        expect(subject).to eq({"value" => 2, "use_offset" => false, "direction" => "next", "size" => 25})
      end

      it "should generate a valid token for direction prev" do
        cursor = create_cursor(1, "next", -1).save([OpenStruct.new(id: 1), OpenStruct.new(id: 2)], "previous")
        subject = decode_cursor(cursor)
        expect(subject).to eq({"value" => 1, "use_offset" => false, "direction" => "previous", "size" => 25})
      end

      it "should generate a valid token for direction first" do
        cursor = create_cursor(1, "next", -1).save([OpenStruct.new(id: 1), OpenStruct.new(id: 2)], "first")
        subject = decode_cursor(cursor)
        expect(subject).to eq({"value" => nil, "use_offset" => false, "direction" => "next", "size" => 25})
      end
    end

    describe "when using offset based pagination" do
      it "should generate a valid token for direction next" do
        cursor = create_cursor(30, "next", -1).save([OpenStruct.new(id: 1), OpenStruct.new(id: 2)], "next", use_offset: true)
        subject = decode_cursor(cursor)
        expect(subject).to eq({"value" => 55, "use_offset" => true, "direction" => "next", "size" => 25})
      end

      it "should generate a valid token for direction prev" do
        cursor = create_cursor(30, "next", -1).save([OpenStruct.new(id: 1), OpenStruct.new(id: 2)], "previous", use_offset: true)
        subject = decode_cursor(cursor)
        expect(subject).to eq({"value" => 5, "use_offset" => true, "direction" => "previous", "size" => 25})
      end

      it "should generate a valid token for direction first" do
        cursor = create_cursor(30, "next", -1).save([OpenStruct.new(id: 1), OpenStruct.new(id: 2)], "first", use_offset: true)
        subject = decode_cursor(cursor)
        expect(subject).to eq({"value" => nil, "use_offset" => true, "direction" => "next", "size" => 25})
      end
    end
  end
end
