# -*- encoding : utf-8 -*-

require 'spec_helper'

describe "Exchange::Currencies" do
  let(:subject) { Exchange::Currencies }

  describe "self.defines?" do
    context "with a defined currency" do
      it "should return true" do
        subject.currencies.each do |curr|
          expect(subject).to be_defines(curr)
        end
      end
    end

    context "with a defined country" do
      it "should return true" do
        subject.country_map.each do |country, currency|
          expect(subject).to be_defines(country)
        end
      end
    end

    context "with an undefined currency" do
      it "should return false" do
        expect(subject).not_to be_defines(:xxx)
      end
    end
  end

  describe "self.assert_currency" do
    context "with a currency" do
      it "should return the currency itself" do
        expect(subject.assert_currency!(:eur)).to eq(:eur)
      end
    end

    context "with a country" do
      it "should return the matching currency for the country" do
        expect(subject.assert_currency!(:de)).to eq(:eur)
      end
    end

    context "with a non-currency" do
      it "should raise an error" do
        expect { subject.assert_currency!(:xxx) }.to raise_error(Exchange::NoCurrencyError, "xxx is not a currency nor a country code matchable to a currency")
      end
    end
  end

  describe "self.instantiate" do
    context "given a float or an integer" do
      context "with bigger precision than the definition" do
        it "should instantiate a big decimal with the given precision" do
          expect(BigDecimal).to receive(:new).with('23.2345', 6).and_return('INSTANCE')
          expect(subject.instantiate(23.2345, :tnd)).to eq('INSTANCE')
          expect(BigDecimal).to receive(:new).with('22223.2323444', 12).and_return('INSTANCE')
          expect(subject.instantiate(22223.2323444, :sar)).to eq('INSTANCE')
          expect(BigDecimal).to receive(:new).with('23.23', 4).and_return('INSTANCE')
          expect(subject.instantiate(23.23, :clp)).to eq('INSTANCE')
        end
      end

      context "with smaller precision than the definition" do
        it "should instantiate a big decimal with the defined precision" do
          expect(BigDecimal).to receive(:new).with('23382343.1',11).and_return('INSTANCE')
          expect(subject.instantiate(23382343.1, :tnd)).to eq('INSTANCE')
          expect(BigDecimal).to receive(:new).with('23',4).and_return('INSTANCE')
          expect(subject.instantiate(23, :sar)).to eq('INSTANCE')
          expect(BigDecimal).to receive(:new).with('23.2',5).and_return('INSTANCE')
          expect(subject.instantiate(23.2, :omr)).to eq('INSTANCE')
        end
      end
    end

    context "given a float with scientific notation" do
      context "with bigger precision than the definition" do
        it "should instantiate a big decimal with the given precision" do
          expect(BigDecimal).to receive(:new).with("6.0e-05",6).and_return('INSTANCE')
          expect(subject.instantiate(6.0e-05, :tnd)).to eq('INSTANCE')
          expect(BigDecimal).to receive(:new).with("600000.0",8).and_return('INSTANCE')
          expect(subject.instantiate(6.0e05, :sar)).to eq('INSTANCE')
          expect(BigDecimal).to receive(:new).with("1.456e-08",12).and_return('INSTANCE')
          expect(subject.instantiate(1.456e-08, :omr)).to eq('INSTANCE')
          expect(BigDecimal).to receive(:new).with("145600000.0",12).and_return('INSTANCE')
          expect(subject.instantiate(1.456e08, :omr)).to eq('INSTANCE')
        end
      end

      context "with smaller precision than the definition" do
        it "should instantiate a big decimal with the defined precision" do
          expect(BigDecimal).to receive(:new).with("0.6",4).and_return('INSTANCE')
          expect(subject.instantiate(6.0e-01, :tnd)).to eq('INSTANCE')
          expect(BigDecimal).to receive(:new).with("60.0",4).and_return('INSTANCE')
          expect(subject.instantiate(6.0e01, :sar)).to eq('INSTANCE')
          expect(BigDecimal).to receive(:new).with("0.14",4).and_return('INSTANCE')
          expect(subject.instantiate(1.4e-01, :omr)).to eq('INSTANCE')
          expect(BigDecimal).to receive(:new).with("14.56",5).and_return('INSTANCE')
          expect(subject.instantiate(1.456e01, :omr)).to eq('INSTANCE')
        end
      end
    end

    context "given a big decimal" do
      let!(:bigdecimal) { BigDecimal("23.23") }
      it "should instantiate a big decimal according to the iso standards" do
        expect(BigDecimal).to receive(:new).never
        expect(subject.instantiate(bigdecimal, :tnd)).to eq(bigdecimal)
      end
    end
  end

  describe "self.round" do
    it "should round a currency according to ISO 4217 Definitions" do
      expect(subject.round(BigDecimal("23.232524"), :tnd)).to eq(BigDecimal("23.233"))
      expect(subject.round(BigDecimal("23.232524"), :sar)).to eq(BigDecimal("23.23"))
      expect(subject.round(BigDecimal("23.232524"), :clp)).to eq(BigDecimal("23"))
    end

    it "should round psychologically if asked" do
      expect(subject.round(BigDecimal("23.232524"), :tnd, nil, {:psych => true})).to eq(BigDecimal("22.999"))
      expect(subject.round(BigDecimal("23.232524"), :sar, nil, {:psych => true})).to eq(BigDecimal("22.99"))
      expect(subject.round(BigDecimal("23.232524"), :clp, nil, {:psych => true})).to eq(BigDecimal("19"))
    end
  end

  describe "self.ceil" do
    it "should ceil a currency according to ISO 4217 Definitions" do
      expect(subject.ceil(BigDecimal("23.232524"), :tnd)).to eq(BigDecimal("23.233"))
      expect(subject.ceil(BigDecimal("23.232524"), :sar)).to eq(BigDecimal("23.24"))
      expect(subject.ceil(BigDecimal("23.232524"), :clp)).to eq(BigDecimal("24"))
    end

    it "should ceil psychologically if asked" do
      expect(subject.ceil(BigDecimal("23.232524"), :tnd, nil, {:psych => true})).to eq(BigDecimal("23.999"))
      expect(subject.ceil(BigDecimal("23.232524"), :sar, nil, {:psych => true})).to eq(BigDecimal("23.99"))
      expect(subject.ceil(BigDecimal("23.232524"), :clp, nil, {:psych => true})).to eq(BigDecimal("29"))
    end
  end

  describe "self.floor" do
    it "should floor a currency according to ISO 4217 Definitions" do
      expect(subject.floor(BigDecimal("23.232524"), :tnd)).to eq(BigDecimal("23.232"))
      expect(subject.floor(BigDecimal("23.232524"), :sar)).to eq(BigDecimal("23.23"))
      expect(subject.floor(BigDecimal("23.232524"), :clp)).to eq(BigDecimal("23"))
    end

    it "should floor psychologically if asked" do
      expect(subject.floor(BigDecimal("23.232524"), :tnd, nil, {:psych => true})).to eq(BigDecimal("22.999"))
      expect(subject.floor(BigDecimal("23.232524"), :sar, nil, {:psych => true})).to eq(BigDecimal("22.99"))
      expect(subject.floor(BigDecimal("23.232524"), :clp, nil, {:psych => true})).to eq(BigDecimal("19"))
    end
  end

  describe "self.symbol" do
    context "with a symbol present" do
      it "should return the symbol" do
        expect(subject.symbol(:usd)).to eq('$')
        expect(subject.symbol(:gbp)).to eq('£')
        expect(subject.symbol(:eur)).to eq('€')
      end
    end

    context "with no symbol present" do
      it "should return nil" do
        expect(subject.symbol(:chf)).to be_nil
        expect(subject.symbol(:etb)).to be_nil
        expect(subject.symbol(:tnd)).to be_nil
      end
    end
  end

  describe "self.stringify" do
    it "should stringify a currency according to ISO 4217 Definitions" do
      expect(subject.stringify(BigDecimal("23234234.232524"), :tnd)).to eq("TND 23234234.233")
      expect(subject.stringify(BigDecimal("23234234.232524"), :sar)).to eq("SAR 23,234,234.23")
      expect(subject.stringify(BigDecimal("2323434223.232524"), :clp)).to eq("CLP 2.323.434.223")
      expect(subject.stringify(BigDecimal("232344.2"), :tnd)).to eq("TND 232344.200")
      expect(subject.stringify(BigDecimal("233432434.4"), :sar)).to eq("SAR 233,432,434.40")
      expect(subject.stringify(BigDecimal("23234234.0"), :clp)).to eq("CLP 23.234.234")
    end

    context "amount only" do
      it "should not render the currency" do
        expect(subject.stringify(BigDecimal("23.232524"), :tnd, :format => :amount)).to eq("23.233")
        expect(subject.stringify(BigDecimal("223423432343.232524"), :chf, :format => :amount)).to eq("223'423'432'343.23")
        expect(subject.stringify(BigDecimal("23.232524"), :clp, :format => :amount)).to eq("23")
        expect(subject.stringify(BigDecimal("23.2"), :tnd, :format => :amount)).to eq("23.200")
        expect(subject.stringify(BigDecimal("25645645663.4"), :sar, :format => :amount)).to eq("25,645,645,663.40")
        expect(subject.stringify(BigDecimal("23.0"), :clp, :format => :amount)).to eq("23")
      end
    end

    context "plain amount" do
      it "should not render the currency or separators" do
        expect(subject.stringify(BigDecimal("23.232524"), :tnd, :format => :plain)).to eq("23.233")
        expect(subject.stringify(BigDecimal("223423432343.232524"), :chf, :format => :plain)).to eq("223423432343.23")
        expect(subject.stringify(BigDecimal("23.232524"), :clp, :format => :plain)).to eq("23")
        expect(subject.stringify(BigDecimal("23.2"), :tnd, :format => :plain)).to eq("23.200")
        expect(subject.stringify(BigDecimal("25645645663.4"), :sar, :format => :plain)).to eq("25645645663.40")
        expect(subject.stringify(BigDecimal("23.0"), :clp, :format => :plain)).to eq("23")
      end
    end

    context "symbol" do
      context "with a symbol present" do
        it "should render a symbol for the currency" do
          expect(subject.stringify(BigDecimal("23.232524"), :usd, :format => :symbol)).to eq("$23.23")
          expect(subject.stringify(BigDecimal("23.232524"), :irr, :format => :symbol)).to eq("﷼23.23")
          expect(subject.stringify(BigDecimal("345543453453.232524"), :gbp, :format => :symbol)).to eq("£345,543,453,453.23")
          expect(subject.stringify(BigDecimal("23.232524"), :eur, :format => :symbol)).to eq("€23.23")
        end
      end

      context "without a symbol present" do
        it "should render the currency abbreviation" do
          expect(subject.stringify(BigDecimal("32741393.232524"), :chf, :format => :symbol)).to eq("CHF 32'741'393.23")
          expect(subject.stringify(BigDecimal("23.232524"), :etb, :format => :symbol)).to eq("ETB 23.23")
        end
      end
    end
  end
end
