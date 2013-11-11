require 'minitest/spec'
require 'minitest/autorun'

require 'rqrcode/export/png'
require 'rqrcode/export/svg'
require 'rqrcode/export/html'

# fix for require_relative in < 1.9
unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end
end

require_relative "../lib/rqrcode"

describe :QRCodeExportTest do
  # require_relative "data"

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
