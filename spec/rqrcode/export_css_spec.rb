require 'spec_helper'

describe 'Export::CSS' do
  it 'must respond_to css' do
    expect(RQRCode::QRCode.new('css')).to respond_to(:as_css)
  end

  it 'must export to css' do
    expect(RQRCode::QRCode.new('css').as_css).to eq(AS_CSS)
  end
end
