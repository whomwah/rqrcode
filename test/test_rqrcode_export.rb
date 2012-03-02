require 'minitest/spec'
require 'minitest/autorun'

require 'rqrcode/export/png'
require 'rqrcode/export/svg'

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

  [:svg, :png].each do |ext|
    it "must respond_to to #{ext}" do
      RQRCode::QRCode.new('x').must_respond_to :"as_#{ext}"
    end
  end

  it "must export to png file" do
    RQRCode::QRCode.new('png', :size => 20).as_png.must_be_instance_of ChunkyPNG::Image
  end

  it "must export to svg file" do
     RQRCode::QRCode.new('png').as_svg.must_match(/<\/svg>/)
  end


end
