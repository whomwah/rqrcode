require 'test_helper'

describe 'Export::PNG' do
  it 'must respond_to png' do
    RQRCode::QRCode.new('x').must_respond_to :as_png
  end

  it 'must export to png file' do
    RQRCode::QRCode.new('png').as_png.must_be_instance_of ChunkyPNG::Image
  end
end
