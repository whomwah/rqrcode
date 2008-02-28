require "test/unit"
require "lib/rqrcode"

class QRCodeTest < Test::Unit::TestCase
  require "test/test_data"
 
  def test_no_data_given
    assert_raise(RQRCode::QRCodeArgumentError) {
      RQRCode::QRCode.new( :size => 1, :level => :h )
      RQRCode::QRCode.new( :size => 1 )
      RQRCode::QRCode.new
    }
    assert_raise(RQRCode::QRCodeRunTimeError) {
      qr = RQRCode::QRCode.new('duncan')
      qr.is_dark(0,999999)
    }
  end

  def test_H_
    qr = RQRCode::QRCode.new( 'duncan', :size => 1 )

    assert_equal qr.modules.size, 21
    assert_equal qr.modules, MATRIX_1_H

    qr = RQRCode::QRCode.new( 'duncan', :size => 1 )
    assert_equal qr.modules, MATRIX_1_H
    qr = RQRCode::QRCode.new( 'duncan', :size => 1, :level => :l )
    assert_equal qr.modules, MATRIX_1_L
    qr = RQRCode::QRCode.new( 'duncan', :size => 1, :level => :m )
    assert_equal qr.modules, MATRIX_1_M
    qr = RQRCode::QRCode.new( 'duncan', :size => 1, :level => :q )
    assert_equal qr.modules, MATRIX_1_Q
  end

  def test_3_H_
    qr = RQRCode::QRCode.new( 'duncan', :size => 3 )

    assert_equal qr.modules.size, 29
    assert_equal qr.modules, MATRIX_3_H
  end

  def test_5_H_
    qr = RQRCode::QRCode.new( 'duncan', :size => 5 )

    assert_equal qr.modules.size, 37
    assert_equal qr.modules, MATRIX_5_H
  end

  def test_10_H_
    qr = RQRCode::QRCode.new( 'duncan', :size => 10 )

    assert_equal qr.modules.size, 57
    assert_equal qr.modules, MATRIX_10_H
  end

  def test_4_H_
    qr = RQRCode::QRCode.new('www.bbc.co.uk/programmes/b0090blw',
      :level => :l )
    assert_equal qr.modules, MATRIX_4_L
    qr = RQRCode::QRCode.new('www.bbc.co.uk/programmes/b0090blw',
      :level => :m )
    assert_equal qr.modules, MATRIX_4_M
    qr = RQRCode::QRCode.new('www.bbc.co.uk/programmes/b0090blw',
      :level => :q )
    assert_equal qr.modules, MATRIX_4_Q

    qr = RQRCode::QRCode.new('www.bbc.co.uk/programmes/b0090blw')
    assert_equal qr.modules.size, 33
    assert_equal qr.modules, MATRIX_4_H
  end

  def test_to_s
    qr = RQRCode::QRCode.new( 'duncan', :size => 1 )
    assert_equal qr.to_s[0..21], "xxxxxxx xx x  xxxxxxx\n"
    assert_equal qr.to_s( :true => 'q', :false => 'n' )[0..21], "qqqqqqqnqqnqnnqqqqqqq\n"
    assert_equal qr.to_s( :true => '@' )[0..21], "@@@@@@@ @@ @  @@@@@@@\n"
  end
end
