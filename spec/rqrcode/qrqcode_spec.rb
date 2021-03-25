require "spec_helper"
require "rqrcode/data"

describe "RQRCode" do
  it "must provide a custom to_s" do
    qr = RQRCode::QRCode.new("http://kyan.com", size: 3)
    expect(qr.to_s[0..50]).to eq("xxxxxxx   x x  xxx    xxxxxxx\nx     x  xxxxx  x x  ")
    expect(qr.to_s(dark: "q", light: "n")[0..36]).to eq("qqqqqqqnnnqnqnnqqqnnnnqqqqqqq\nqnnnnnq")
    expect(qr.to_s(dark: "@")[0..21]).to eq("@@@@@@@   @ @  @@@    ")
  end

  it "must expose the core qrcode" do
    expect(RQRCode::QRCode.new("svg").qrcode).to be_instance_of(RQRCodeCore::QRCode)
  end

  it "should do a basic render" do
    qr = RQRCode::QRCode.new("http://kyan.com")
    str = ""

    qr.qrcode.modules.each do |row|
      row.each do |col|
        str << (col ? "X" : "O")
      end

      str << "\n"
    end

    expect(str).to eq(AS_BASIC)
  end

  it 'should do a basic render using old "modules" interface' do
    qr = RQRCode::QRCode.new("http://kyan.com")
    str = ""

    qr.modules.each do |row|
      row.each do |col|
        str << (col ? "X" : "O")
      end

      str << "\n"
    end

    expect(str).to eq(AS_BASIC)
  end

  it "should pass options to rqrcode_core" do
    options = {
      size: 5,
      mode: :alphanumeric
    }

    qr = RQRCode::QRCode.new("QRCODE", options)

    expect(qr.qrcode.mode).to eq(:mode_alpha_numk)
    expect(qr.qrcode.version).to eq(options[:size])
  end
end
