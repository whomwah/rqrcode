require File.join(File.dirname(__FILE__), "..", "test_helper")

class QRCodeTest < Test::Unit::TestCase
	require File.dirname(__FILE__) + "/test_data"
  
  def test_full_functionality
		qr = RQRCode::QRCode.new( :size => 1 )
		qr.add_data('duncan')
		qr.make

    assert_equal qr.modules.length, 21
    assert_equal qr.module_count, 21
		assert_equal qr.modules, MATRIX_1_H
  end

end
