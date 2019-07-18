require 'test_helper'
require 'rqrcode/data'

describe 'Export::ANSI' do
  it 'must respond_to ansi' do
    RQRCode::QRCode.new('x').must_respond_to :as_ansi
  end

  it 'must export to ansi' do
    RQRCode::QRCode.new('ansi').as_ansi.must_equal(AS_ANSI)
  end
end
