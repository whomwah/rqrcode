require File.join(File.dirname(__FILE__), "..", "test_helper")

class QRCodeTest < Test::Unit::TestCase
	require File.dirname(__FILE__) + "/test_data"
  
  def test_1_H_
		qr = RQRCode::QRCode.new( 'duncan', :size => 1 )

    assert_equal qr.modules.length, 21
    assert_equal qr.module_count, 21
		assert_equal qr.modules, MATRIX_1_H

		qr = RQRCode::QRCode.new( 'duncan', :size => 1 )
		assert_equal qr.modules, MATRIX_1_H
  end

  def test_3_H_
		qr = RQRCode::QRCode.new( 'duncan', :size => 3 )

    assert_equal qr.modules.length, 29
    assert_equal qr.module_count, 29
		assert_equal qr.modules, MATRIX_3_H
  end

  def test_5_H_
		qr = RQRCode::QRCode.new( 'duncan', :size => 5 )

    assert_equal qr.modules.length, 37
    assert_equal qr.module_count, 37
		assert_equal qr.modules, MATRIX_5_H
  end

  def test_10_H_
		qr = RQRCode::QRCode.new( 'duncan', :size => 10 )

    assert_equal qr.modules.length, 57
    assert_equal qr.module_count, 57
		assert_equal qr.modules, MATRIX_10_H
  end

  def test_4_H_
		qr = RQRCode::QRCode.new('www.bbc.co.uk/programmes/b0090blw')

    assert_equal qr.modules.length, 33
    assert_equal qr.module_count, 33
		assert_equal qr.modules, MATRIX_4_H
  end
end
