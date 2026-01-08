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

  context "with offset_x and offset_y options" do
    it "applies different x and y offsets with use_path for smaller output" do
      expect(RQRCode::QRCode.new("https://kyan.com").as_svg(
        use_path: true,
        offset_x: 20,
        offset_y: 30
      )).to eq(AS_SVG7)
    end

    it "uses offset as fallback when specific offsets aren't provided" do
      expect(RQRCode::QRCode.new("https://kyan.com").as_svg(
        use_path: true,
        offset: 25
      )).to eq(AS_SVG8)
    end
  end

  context "with fill and offset options combined" do
    it "combines fill with global offset" do
      expect(RQRCode::QRCode.new("https://kyan.com").as_svg(
        use_path: true,
        fill: "ccffcc",
        offset: 10
      )).to eq(AS_SVG9)
    end

    it "combines fill with specific offsets" do
      expect(RQRCode::QRCode.new("https://kyan.com").as_svg(
        use_path: true,
        fill: "ccffcc",
        offset_x: 15,
        offset_y: 20
      )).to eq(AS_SVG10)
    end
  end

  context "with shape_rendering option" do
    it "uses default crispEdges when not specified" do
      svg = RQRCode::QRCode.new("test").as_svg
      expect(svg).to include('shape-rendering="crispEdges"')
    end

    it "applies custom shape_rendering value" do
      svg = RQRCode::QRCode.new("test").as_svg(shape_rendering: "geometricPrecision")
      expect(svg).to include('shape-rendering="geometricPrecision"')
    end

    it "supports optimizeSpeed shape_rendering" do
      svg = RQRCode::QRCode.new("test").as_svg(shape_rendering: "optimizeSpeed")
      expect(svg).to include('shape-rendering="optimizeSpeed"')
    end
  end

  context "SVG element structure" do
    it "generates rect elements when use_path is false (default)" do
      svg = RQRCode::QRCode.new("test").as_svg
      expect(svg).to include("<rect ")
      expect(svg).not_to include("<path ")
    end

    it "generates path element when use_path is true" do
      svg = RQRCode::QRCode.new("test").as_svg(use_path: true)
      expect(svg).to include("<path ")
      expect(svg).not_to include("<rect ")
    end

    it "includes XML declaration when standalone is true (default)" do
      svg = RQRCode::QRCode.new("test").as_svg
      expect(svg).to start_with('<?xml version="1.0" standalone="yes"?>')
    end

    it "includes required SVG namespace attributes" do
      svg = RQRCode::QRCode.new("test").as_svg
      expect(svg).to include('xmlns="http://www.w3.org/2000/svg"')
      expect(svg).to include('xmlns:xlink="http://www.w3.org/1999/xlink"')
      expect(svg).to include('version="1.1"')
    end

    it "closes SVG tag properly" do
      svg = RQRCode::QRCode.new("test").as_svg
      expect(svg).to end_with("</svg>")
    end
  end

  context "dimension calculations" do
    let(:qr) { RQRCode::QRCode.new("test") }
    let(:module_count) { qr.instance_variable_get(:@qrcode).module_count }

    it "calculates dimensions based on module_count and default module_size" do
      svg = qr.as_svg
      expected_size = module_count * 11 # default module_size is 11
      expect(svg).to include(%(width="#{expected_size}" height="#{expected_size}"))
    end

    it "calculates dimensions with custom module_size" do
      svg = qr.as_svg(module_size: 5)
      expected_size = module_count * 5
      expect(svg).to include(%(width="#{expected_size}" height="#{expected_size}"))
    end

    it "includes offsets in dimension calculations" do
      svg = qr.as_svg(module_size: 10, offset: 20)
      expected_size = (module_count * 10) + (2 * 20)
      expect(svg).to include(%(width="#{expected_size}" height="#{expected_size}"))
    end

    it "calculates asymmetric dimensions with different x and y offsets" do
      svg = qr.as_svg(module_size: 10, offset_x: 15, offset_y: 25)
      expected_width = (module_count * 10) + (2 * 15)
      expected_height = (module_count * 10) + (2 * 25)
      expect(svg).to include(%(width="#{expected_width}" height="#{expected_height}"))
    end
  end

  context "color handling" do
    it "prefixes hex color with # for color option" do
      svg = RQRCode::QRCode.new("test").as_svg(use_path: true, color: "ff0000")
      expect(svg).to include('fill="#ff0000"')
    end

    it "prefixes hex color with # for fill option" do
      svg = RQRCode::QRCode.new("test").as_svg(use_path: true, fill: "00ff00")
      expect(svg).to include('fill="#00ff00"')
    end

    it "does not prefix symbol colors" do
      svg = RQRCode::QRCode.new("test").as_svg(use_path: true, color: :blue)
      expect(svg).to include('fill="blue"')
      expect(svg).not_to include('fill="#blue"')
    end

    it "uses default color 000 when not specified" do
      svg = RQRCode::QRCode.new("test").as_svg(use_path: true)
      expect(svg).to include('fill="#000"')
    end

    it "supports 3-character hex codes" do
      svg = RQRCode::QRCode.new("test").as_svg(use_path: true, color: "f00")
      expect(svg).to include('fill="#f00"')
    end
  end

  context "viewbox with use_rect" do
    it "uses viewBox attribute instead of width/height" do
      qr = RQRCode::QRCode.new("test")
      svg = qr.as_svg(viewbox: true) # use_rect is default
      module_count = qr.instance_variable_get(:@qrcode).module_count
      expected_size = module_count * 11

      expect(svg).to include(%(viewBox="0 0 #{expected_size} #{expected_size}"))
      expect(svg).not_to include(%(width="#{expected_size}"))
      expect(svg).not_to include(%(height="#{expected_size}"))
    end
  end

  context "fill background with use_rect" do
    it "adds background rect before module rects" do
      svg = RQRCode::QRCode.new("test").as_svg(fill: "ffffff")
      # Background rect should be first rect after svg open tag
      expect(svg).to match(/<svg[^>]*><rect[^>]*fill="#ffffff"/)
    end
  end

  context "standalone false with use_rect" do
    it "outputs only rect elements without XML declaration or SVG wrapper" do
      svg = RQRCode::QRCode.new("test").as_svg(standalone: false)
      expect(svg).not_to include("<?xml")
      expect(svg).not_to include("<svg")
      expect(svg).not_to include("</svg>")
      expect(svg).to include("<rect ")
    end
  end

  context "multiple svg_attributes" do
    it "renders multiple custom attributes" do
      svg = RQRCode::QRCode.new("test").as_svg(
        svg_attributes: {
          :id => "qr-code",
          :class => "qr-image",
          "data-content" => "test",
          :role => "img"
        }
      )
      expect(svg).to include('id="qr-code"')
      expect(svg).to include('class="qr-image"')
      expect(svg).to include('data-content="test"')
      expect(svg).to include('role="img"')
    end
  end

  context "with different QR code complexities" do
    it "handles short content" do
      svg = RQRCode::QRCode.new("a").as_svg(use_path: true)
      expect(svg).to include("<path ")
      expect(svg).to include("</svg>")
    end

    it "handles URL content" do
      svg = RQRCode::QRCode.new("https://example.com/path?query=value").as_svg(use_path: true)
      expect(svg).to include("<path ")
      expect(svg).to include("</svg>")
    end

    it "handles content with special characters" do
      svg = RQRCode::QRCode.new("Hello, World! @#$%").as_svg(use_path: true)
      expect(svg).to include("<path ")
      expect(svg).to include("</svg>")
    end
  end

  context "path output compactness" do
    it "generates smaller output with use_path than use_rect for same content" do
      qr = RQRCode::QRCode.new("https://example.com")
      svg_rect = qr.as_svg(use_path: false)
      svg_path = qr.as_svg(use_path: true)

      expect(svg_path.length).to be < svg_rect.length
    end
  end
end
