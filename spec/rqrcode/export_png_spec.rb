require "spec_helper"

describe "Export::PNG" do
  let(:mockImage) { double(:mock_image) }

  before :each do
    allow(mockImage).to receive(:row) { [] }
    allow(mockImage).to receive(:replace_row!)
  end

  it "must respond_to png" do
    expect(RQRCode::QRCode.new("x")).to respond_to(:as_png)
  end

  it "must export to png file" do
    expect(RQRCode::QRCode.new("png").as_png).to be_instance_of(ChunkyPNG::Image)
  end

  it "must export a png using the correct defaults" do
    expect(ChunkyPNG::Image).to receive(:new)
      .once
      .with(120, 120, 4294967295)
      .and_return(mockImage)
    expect(mockImage).not_to receive(:save)

    RQRCode::QRCode.new("png").as_png
  end

  context "with various color inputs" do
    before :each do
      allow(ChunkyPNG).to receive(:Color).and_call_original
      expect(mockImage).to receive(:save)
        .once
        .with("some/path", {bit_depth: 1, color_mode: 0})
    end

    it "should handle the defaults" do
      expect(ChunkyPNG::Image).to receive(:new)
        .once
        .with(174, 174, 4294967295)
        .and_return(mockImage)

      RQRCode::QRCode.new("png").as_png(
        file: "some/path"
      )

      expect(ChunkyPNG).to have_received(:Color).with("black").once
      expect(ChunkyPNG).to have_received(:Color).with("white").once
    end

    it "should handle a blue 'color'" do
      expect(ChunkyPNG::Image).to receive(:new)
        .once
        .with(174, 174, 4294967295)
        .and_return(mockImage)

      RQRCode::QRCode.new("png").as_png(
        file: "some/path",
        color: "blue"
      )

      expect(ChunkyPNG).to have_received(:Color).with("blue").once
      expect(ChunkyPNG).to have_received(:Color).with("white").once
    end

    it "should handle a #FC0000 'color'" do
      expect(ChunkyPNG::Image).to receive(:new)
        .once
        .with(174, 174, 4294967295)
        .and_return(mockImage)

      RQRCode::QRCode.new("png").as_png(
        file: "some/path",
        color: "#FC0000"
      )

      expect(ChunkyPNG).to have_received(:Color).with("#FC0000").once
      expect(ChunkyPNG).to have_received(:Color).with("white").once
    end

    it "should handle an rgb 'color'" do
      expect(ChunkyPNG::Image).to receive(:new)
        .once
        .with(174, 174, 4294967295)
        .and_return(mockImage)

      RQRCode::QRCode.new("png").as_png(
        file: "some/path",
        color: [0, 0, 0]
      )

      expect(ChunkyPNG).to have_received(:Color).with(0, 0, 0).once
      expect(ChunkyPNG).to have_received(:Color).with("white").once
    end

    it "should handle a green 'fill'" do
      expect(ChunkyPNG::Image).to receive(:new)
        .once
        .with(174, 174, 8388863)
        .and_return(mockImage)

      RQRCode::QRCode.new("png").as_png(
        file: "some/path",
        fill: "green"
      )

      expect(ChunkyPNG).to have_received(:Color).with("black").once
      expect(ChunkyPNG).to have_received(:Color).with("green").once
    end

    it "should handle an rgb 'fill'" do
      expect(ChunkyPNG::Image).to receive(:new)
        .once
        .with(174, 174, 4294967295)
        .and_return(mockImage)

      RQRCode::QRCode.new("png").as_png(
        file: "some/path",
        fill: [255, 255, 255]
      )

      expect(ChunkyPNG).to have_received(:Color).with("black").once
      expect(ChunkyPNG).to have_received(:Color).with(255, 255, 255).once
    end
  end

  it "should not handle nonsense color " do
    expect {
      RQRCode::QRCode.new("png").as_png(
        file: "some/path",
        color: "madeupcolor"
      )
    }.to raise_error(ArgumentError, "Unknown color name madeupcolor!")
  end

  it "should not handle nonsense fill " do
    expect {
      RQRCode::QRCode.new("png").as_png(
        file: "some/path",
        fill: "madeupcolor"
      )
    }.to raise_error(ArgumentError, "Unknown color name madeupcolor!")
  end

  context "pixel content" do
    # A 29x29 QR code (version 3)
    let(:qrcode) { RQRCode::QRCode.new("http://github.com/") }
    let(:black) { ChunkyPNG::Color("black") }
    let(:white) { ChunkyPNG::Color("white") }

    # Every pixel must be `color` when the module it falls in is dark, and
    # `fill` everywhere else, border included.
    def expect_pixels(png, size:, module_px:, offset:, color:, fill:)
      matrix = qrcode.qrcode
      count = matrix.module_count
      expect(png.width).to eq(size)
      expect(png.height).to eq(size)

      wrong = []
      size.times do |py|
        size.times do |px|
          row = (py - offset).div(module_px)
          col = (px - offset).div(module_px)
          dark = row.between?(0, count - 1) && col.between?(0, count - 1) && matrix.checked?(row, col)
          wrong << [px, py] unless png[px, py] == (dark ? color : fill)
        end
      end
      expect(wrong.first(10)).to eq([])
    end

    it "renders the defaults" do
      # 120 / (29 + 2 * 4) = 3px modules, (120 - 87) / 2 = 16px left/top border
      png = qrcode.as_png
      expect_pixels(png, size: 120, module_px: 3, offset: 16, color: black, fill: white)
    end

    it "centers the modules within size, the odd pixel going right and bottom" do
      # 201 / (29 + 2 * 1) = 6px modules, (201 - 174) / 2 = 13px left/top border, 14px right/bottom
      png = qrcode.as_png(size: 201, border_modules: 1, color: [200, 0, 0], fill: "#f0f0f0")
      expect_pixels(png, size: 201, module_px: 6, offset: 13,
        color: ChunkyPNG::Color.rgb(200, 0, 0), fill: ChunkyPNG::Color.from_hex("#f0f0f0"))
    end

    it "renders module_px_size and border_modules" do
      # (29 + 2 * 2) * 3 = 99px, with a 2 * 3 = 6px border
      png = qrcode.as_png(module_px_size: 3, border_modules: 2, color: "navy", fill: "yellow")
      expect_pixels(png, size: 99, module_px: 3, offset: 6,
        color: ChunkyPNG::Color("navy"), fill: ChunkyPNG::Color("yellow"))
    end

    it "renders resize_gte_to" do
      # ceil(100 / (29 + 2 * 1)) = 4px modules, (29 + 2) * 4 = 124px, with a 4px border
      png = qrcode.as_png(resize_gte_to: 100, border_modules: 1, color: "green", fill: "white")
      expect_pixels(png, size: 124, module_px: 4, offset: 4, color: ChunkyPNG::Color("green"), fill: white)
    end

    it "renders resize_exactly_to as the unscaled image resized" do
      options = {module_px_size: 3, border_modules: 2, color: "navy", fill: "yellow"}
      png = qrcode.as_png(options.merge(resize_exactly_to: 90))
      expect(png).to eq(qrcode.as_png(options).resize(90, 90))
    end

    it "returns an empty image when size leaves no pixel per module" do
      png = qrcode.as_png(size: 0)
      expect([png.width, png.height]).to eq([0, 0])
    end
  end

  context "with file save and constaints" do
    it "should export using the correct defaults" do
      expect(ChunkyPNG::Image).to receive(:new)
        .once
        .with(174, 174, 4294967295)
        .and_return(mockImage)
      expect(mockImage).to receive(:save)
        .once
        .with("some/path", {bit_depth: 1, color_mode: 0})

      RQRCode::QRCode.new("png").as_png(
        file: "some/path"
      )
    end

    it "should export using custom constraints" do
      expect(ChunkyPNG::Image).to receive(:new)
        .once
        .with(174, 174, 4294967295)
        .and_return(mockImage)
      expect(mockImage).to receive(:save)
        .once
        .with("some/path", {
          bit_depth: 8,
          color_mode: 2,
          interlace: true,
          compression: 5
        })

      RQRCode::QRCode.new("png").as_png(
        color_mode: ChunkyPNG::COLOR_TRUECOLOR,
        bit_depth: 8,
        file: "some/path",
        color: "red",
        interlace: true,
        compression: 5
      )
    end

    it "should save" do
      qrcode = RQRCode::QRCode.new("http://github.com/")
      png = qrcode.as_png(
        bit_depth: 1,
        border_modules: 4,
        color_mode: ChunkyPNG::COLOR_GRAYSCALE,
        color: "black",
        file: nil,
        fill: "white",
        module_px_size: 6,
        resize_exactly_to: false,
        resize_gte_to: false,
        size: 120
      )
      IO.binwrite("/tmp/github-qrcode.png", png.to_s)
      expect(IO.binread("/tmp/github-qrcode.png")).to eq png.to_s
    end
  end
end
