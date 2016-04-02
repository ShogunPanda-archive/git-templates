require "spec_helper"

describe ApplicationController do
  describe "#handle_cors", type: :controller do
    it "should render the right content" do
      get(:handle_cors, path: "/foo")
      expect(response).to have_http_status(204)
      expect(response.body).to be_empty
    end
  end
end
