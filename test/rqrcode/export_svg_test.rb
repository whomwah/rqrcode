require 'test_helper'
require 'rqrcode/data'

describe 'Export::SVG' do
  it 'must respond_to svg' do
    RQRCode::QRCode.new('qrcode').must_respond_to :'as_svg'
  end

  it 'must export to svg' do
    RQRCode::QRCode.new('qrcode').as_svg.must_equal(AS_SVG)
  end
end
