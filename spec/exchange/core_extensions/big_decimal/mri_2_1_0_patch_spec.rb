# -*- encoding : utf-8 -*-

if Exchange::BROKEN_BIG_DECIMAL_DIVISION
  require 'spec_helper'

  describe "Exchange::MRI210Patch" do

    describe "/" do
      subject { BigDecimal("0.7") }
      let(:other) { BigDecimal("0.5") }
      it "should patch BigDecimal division for BigDecimals below 1" do
        expect(subject / other).to eq(BigDecimal("1.4"))
        expect(subject.div(other)).to eq(BigDecimal("1.4"))
      end
    end

  end
end
