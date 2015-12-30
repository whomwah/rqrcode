require 'helper'

describe :QRCodeExportTest do

  [:svg, :png, :html].each do |ext|
    it "must respond_to #{ext}" do
      RQRCode::QRCode.new('x').must_respond_to :"as_#{ext}"
    end
  end

  it "must export to png file" do
    RQRCode::QRCode.new('png').as_png.must_be_instance_of ChunkyPNG::Image
  end

  it "must export to svg file" do
    RQRCode::QRCode.new('svg').as_svg.must_match(/<\/svg>/)
  end

  it "must export to html" do
    RQRCode::QRCode.new('html').as_html.must_match(/<table>.+<\/table>/)
  end

end
