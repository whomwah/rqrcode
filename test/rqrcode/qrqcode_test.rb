require 'test_helper'
require 'rqrcode/data'

describe 'RQRCode' do
  it 'must provide a custom to_s' do
    qr = RQRCode::QRCode.new('http://kyan.com', size: 3)
    qr.to_s[0..50].must_equal("xxxxxxx   x x  xxx    xxxxxxx\nx     x  xxxxx  x x  ")
    qr.to_s(true: 'q', false: 'n')[0..36].must_equal("qqqqqqqnnnqnqnnqqqnnnnqqqqqqq\nqnnnnnq")
    qr.to_s(true: '@')[0..21].must_equal("@@@@@@@   @ @  @@@    ")
  end

  it 'must expose the core qrcode' do
    RQRCode::QRCode.new('svg').qrcode.must_be_instance_of(RQRCodeCore::QRCode)
  end


  it 'should do a basic render' do
    qr = RQRCode::QRCode.new('http://kyan.com')
    str = ''

    qr.qrcode.modules.each do |row|
      row.each do |col|
        str << (col ? 'X' : 'O')
      end

      str << "\n"
    end

    str.must_equal(AS_BASIC)
  end

  it 'should do a basic render using old "modules" interface' do
    qr = RQRCode::QRCode.new('http://kyan.com')
    str = ''

    qr.modules.each do |row|
      row.each do |col|
        str << (col ? 'X' : 'O')
      end

      str << "\n"
    end

    str.must_equal(AS_BASIC)
  end

  it 'should pass options to rqrcode_core' do
    options = {
      size: 5,
      mode: :alphanumeric
    }

    qr = RQRCode::QRCode.new('QRCODE', options)

    qr.qrcode.mode.must_equal :mode_alpha_numk
    qr.qrcode.version.must_equal options[:size]
  end
end
