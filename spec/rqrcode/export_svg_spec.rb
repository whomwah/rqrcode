require "spec_helper"
require "rqrcode/data"

describe "Export::SVG" do
  it "must respond_to svg" do
    expect(RQRCode::QRCode.new("qrcode")).to respond_to(:as_svg)
  end

  context "with use_rect (default) option" do
    it "must export to svg" do
      expect(RQRCode::QRCode.new("https://kyan.com").as_svg).to eq(AS_SVG)
    end
  end

  context "with use_path option" do
    it "must export to svg" do
      expect(RQRCode::QRCode.new("https://kyan.com").as_svg(
        use_path: true
      )).to eq(AS_SVG1)
    end
  end

  context "with various options" do
    it "must export to svg" do
      expect(RQRCode::QRCode.new("https://kyan.com").as_svg(
        module_size: 10,
        use_path: true,
        offset: 40,
        color: "ff0000",
        fill: "ffcc00"
      )).to eq(AS_SVG2)
    end
  end

  context "standalone false" do
    it "will not include the <xml>" do
      expect(RQRCode::QRCode.new("https://kyan.com").as_svg(
        standalone: false,
        use_path: true
      )).to eq(AS_SVG3)
    end
  end

  context "viewbox true" do
    it "will use the viewBox attr" do
      expect(RQRCode::QRCode.new("https://kyan.com").as_svg(
        viewbox: true,
        use_path: true
      )).to eq(AS_SVG4)
    end
  end

  context "svg_attributes" do
    it "renders `svg_attributes` when provided " do
      expect(RQRCode::QRCode.new("qrcode").as_svg(
        use_path: true,
        svg_attributes: {
          id: "myUniqueId",
          class: "myClass"
        }
      )).to eq(AS_SVG5)
    end
  end

  context "with color name (symbol)" do
    it "does not include # prefix for color" do
      expect(RQRCode::QRCode.new("https://kyan.com").as_svg(
        use_path: true,
        color: :red,
        fill: :yellow
      )).to eq(AS_SVG6)
    end
  end
end
