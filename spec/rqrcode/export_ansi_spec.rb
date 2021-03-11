require "spec_helper"
require "rqrcode/data"

describe "Export::ANSI" do
  it "must respond_to ansi" do
    expect(RQRCode::QRCode.new("x")).to respond_to(:as_ansi)
  end

  it "must export to ansi" do
    expect(RQRCode::QRCode.new("ansi").as_ansi).to eq(AS_ANSI)
  end
end
