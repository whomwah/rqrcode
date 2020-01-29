require 'spec_helper'

describe 'Export::PNG' do
  let(:mockImage) { double(:mock_image) }

  before :each do
    allow(mockImage).to receive(:[]=)
  end


  it 'must respond_to png' do
    expect(RQRCode::QRCode.new('x')).to respond_to(:as_png)
  end

  it 'must export to png file' do
    expect(RQRCode::QRCode.new('png').as_png).to be_instance_of(ChunkyPNG::Image)
  end

  it 'must export a png using the correct defaults' do
    expect(ChunkyPNG::Image).to receive(:new)
      .once
      .with(120, 120, 4294967295)
      .and_return(mockImage)
    expect(mockImage).not_to receive(:save)

    RQRCode::QRCode.new('png').as_png
  end

  context 'with file save and constaints' do
    it 'should export using the correct defaults' do
      expect(ChunkyPNG::Image).to receive(:new)
        .once
        .with(174, 174, 4294967295)
        .and_return(mockImage)
      expect(mockImage).to receive(:save)
        .once
        .with('some/path', {bit_depth: 1, color_mode: 0})

      RQRCode::QRCode.new('png').as_png(
        file: 'some/path'
      )
    end

    it 'should export using custom constraints' do
      expect(ChunkyPNG::Image).to receive(:new)
        .once
        .with(174, 174, 4294967295)
        .and_return(mockImage)
      expect(mockImage).to receive(:save)
        .once
        .with('some/path', {
          bit_depth: 8,
          color_mode: 2,
          interlace: true,
          compression: 5
        })

      RQRCode::QRCode.new('png').as_png(
        color_mode: ChunkyPNG::COLOR_TRUECOLOR,
        bit_depth: 8,
        file: 'some/path',
        color: 'red',
        interlace: true,
        compression: 5
      )
    end

    it 'should save' do
      qrcode = RQRCode::QRCode.new("http://github.com/")
      png = qrcode.as_png(
        bit_depth: 1,
        border_modules: 4,
        color_mode: ChunkyPNG::COLOR_GRAYSCALE,
        color: 'black',
        file: nil,
        fill: 'white',
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
