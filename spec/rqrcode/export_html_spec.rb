require "spec_helper"

describe "Export::HTML" do
  it "must respond_to html" do
    expect(RQRCode::QRCode.new("html")).to respond_to(:as_html)
  end

  it "must export to html" do
    expect(RQRCode::QRCode.new("html").as_html).to eq(AS_HTML)
  end
end
