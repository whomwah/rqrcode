# encoding: utf-8
require "test/unit"

require_relative "../lib/rqrcode"
class RegresionTests < Test::Unit::TestCase
  
  # Rs block information was incomplete.
  def test_code_length_overflow_bug
    RQRCode::QRCode.new('s' * 220)
    RQRCode::QRCode.new('s' * 195)  
  end
end