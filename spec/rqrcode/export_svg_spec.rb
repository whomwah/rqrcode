require "spec_helper"
require "rqrcode/data"

describe "Export::SVG" do
  it "must respond_to svg" do
    expect(RQRCode::QRCode.new("qrcode")).to respond_to(:as_svg)
  end

  context "with use_rect (default) option" do
    it "must export to svg" do
      expect(RQRCode::QRCode.new("qrcode").as_svg).to eq(AS_SVG)
    end
  end

  context "with use_path option" do
    it "must export to svg" do
      expect(RQRCode::QRCode.new("https://kyan.com").as_svg(
        use_path: true,
        offset: 20
      )).to eq(AS_SVG1)
    end
  end

  describe "options" do
    it "has standalone option true by default" do
      doc = RQRCode::QRCode.new("qrcode").as_svg
      # For now we do very naive pattern matching. The alternative is to
      # include a librariry for parsing XML, like nokogiri. That is a big
      # change for such a small test, though.
      expect(doc).to match(%r{<\?xml.*standalone="yes"})
      expect(doc).to match(%r{<svg.*>})
      expect(doc).to match(%r{</svg>})
    end

    it "omits surrounding XML when `standalone` is `false`" do
      doc = RQRCode::QRCode.new("qrcode").as_svg(standalone: false)
      # For now we do very naive pattern matching. The alternative is to
      # include a librariry for parsing XML, like nokogiri. That is a big
      # change for such a small test, though.
      expect(doc).not_to match(%r{<\?xml.*standalone="yes"})
      expect(doc).not_to match(%r{<svg.*>})
      expect(doc).not_to match(%r{</svg>})
    end
  end
end
