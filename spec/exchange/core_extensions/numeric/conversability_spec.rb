# -*- encoding : utf-8 -*-
require 'spec_helper'

describe "Exchange::Conversability" do
  let(:time) { Time.gm(2012,8,27) }
  let(:test_url) { "http://openexchangerates.org/api/latest.json?app_id=" }
  let(:test_response) { fixture('api_responses/example_json_api.json') }

  before(:all) do
    Exchange.configuration = Exchange::Configuration.new { |c| c.cache = { :subclass => :no_cache } }
  end

  before(:each) do
    allow(Time).to receive(:now).and_return time
  end

  after(:all) do
    Exchange.configuration.reset
  end

  context "with a fixnum" do
    it "should allow to convert to a currency" do
      expect(3.in(:eur)).to be_kind_of Exchange::Money
      expect(3.in(:eur).value).to eq(3)
    end

    it "should allow to convert to a curreny with a negative number" do
      expect(-3.in(:eur)).to be_kind_of Exchange::Money
      expect(-3.in(:eur).value).to eq(-3)
    end

    it "should allow to do full conversions" do
      stub_request(:get, test_url).to_return(body: test_response)
      expect(3.in(:eur).to(:chf)).to be_kind_of Exchange::Money
      expect(3.in(:eur).to(:chf).value.round(2)).to eq(3.62)
      expect(3.in(:eur).to(:chf).currency).to eq(:chf)
      expect(a_request(:get, test_url)).to have_been_made.times(3)
    end

    it "should allow to do full conversions with negative numbers" do
      stub_request(:get, test_url).to_return(body: test_response)
      expect(-3.in(:eur).to(:chf)).to be_kind_of Exchange::Money
      expect(-3.in(:eur).to(:chf).value.round(2)).to eq(-3.62)
      expect(-3.in(:eur).to(:chf).currency).to eq(:chf)
      expect(a_request(:get, test_url)).to have_been_made.times(3)
    end

    it "should allow to define a historic time in which the currency should be interpreted" do
      expect(3.in(:chf, :at => Time.gm(2010,1,1)).time.yday).to eq(1)
      expect(3.in(:chf, :at => Time.gm(2010,1,1)).time.year).to eq(2010)
      expect(3.in(:chf, :at => '2010-01-01').time.year).to eq(2010)
    end

    it "should raise a no currency error if the currency does not exist" do
      expect { 35.in(:zzz) }.to raise_error(Exchange::NoCurrencyError, "zzz is not a currency nor a country code matchable to a currency")
    end
  end

  context "with a float" do
    it "should allow to convert to a currency" do
      expect(3.25.in(:eur)).to be_kind_of Exchange::Money
      expect(3.25.in(:eur).value.round(2)).to eq(3.25)
    end

    it "should allow to convert to a curreny with a negative number" do
      expect(-3.25.in(:eur)).to be_kind_of Exchange::Money
      expect(-3.25.in(:eur).value.round(2)).to eq(-3.25)
    end

    it "should allow to do full conversions" do
      stub_request(:get, test_url).to_return(body: test_response)
      expect(3.25.in(:eur).to(:chf)).to be_kind_of Exchange::Money
      expect(3.25.in(:eur).to(:chf).value.round(2)).to eq(3.92)
      expect(3.25.in(:eur).to(:chf).currency).to eq(:chf)
      expect(a_request(:get, test_url)).to have_been_made.times(3)
    end

    it "should allow to do full conversions with negative numbers" do
      stub_request(:get, test_url).to_return(body: test_response)
      expect(-3.25.in(:eur).to(:chf)).to be_kind_of Exchange::Money
      expect(-3.25.in(:eur).to(:chf).value.round(2)).to eq(-3.92)
      expect(-3.25.in(:eur).to(:chf).currency).to eq(:chf)
      expect(a_request(:get, test_url)).to have_been_made.times(3)
    end

    it "should allow to define a historic time in which the currency should be interpreted" do
      expect(3.25.in(:chf, :at => Time.gm(2010,1,1)).time.yday).to eq(1)
      expect(3.25.in(:chf, :at => Time.gm(2010,1,1)).time.year).to eq(2010)
      expect(3.25.in(:chf, :at => '2010-01-01').time.year).to eq(2010)
    end

    it "should raise a no currency error if the currency does not exist" do
      expect { 35.23.in(:zzz) }.to raise_error(Exchange::NoCurrencyError, "zzz is not a currency nor a country code matchable to a currency")
    end
  end

  context "with a big decimal" do
    it "should allow to convert to a currency" do
      expect(BigDecimal("3.25").in(:eur)).to be_kind_of Exchange::Money
      expect(BigDecimal("3.25").in(:eur).value.round(2)).to eq(3.25)
    end

    it "should allow to convert to a curreny with a negative number" do
      expect(BigDecimal("-3.25").in(:eur)).to be_kind_of Exchange::Money
      expect(BigDecimal("-3.25").in(:eur).value.round(2)).to eq(-3.25)
    end

    it "should allow to do full conversions" do
      stub_request(:get, test_url).to_return(body: test_response)
      expect(BigDecimal("3.25").in(:eur).to(:chf)).to be_kind_of Exchange::Money
      expect(BigDecimal("3.25").in(:eur).to(:chf).value.round(2)).to eq(3.92)
      expect(BigDecimal("3.25").in(:eur).to(:chf).currency).to eq(:chf)
      expect(a_request(:get, test_url)).to have_been_made.times(3)
    end

    it "should allow to do full conversions with negative numbers" do
      stub_request(:get, test_url).to_return(body: test_response)
      expect(BigDecimal("-3.25").in(:eur).to(:chf)).to be_kind_of Exchange::Money
      expect(BigDecimal("-3.25").in(:eur).to(:chf).value.round(2)).to eq(-3.92)
      expect(BigDecimal("-3.25").in(:eur).to(:chf).currency).to eq(:chf)
      expect(a_request(:get, test_url)).to have_been_made.times(3)
    end

    it "should allow to define a historic time in which the currency should be interpreted" do
      expect(BigDecimal("3.25").in(:chf, :at => Time.gm(2010,1,1)).time.yday).to eq(1)
      expect(BigDecimal("3.25").in(:chf, :at => Time.gm(2010,1,1)).time.year).to eq(2010)
      expect(BigDecimal("3.25").in(:chf, :at => '2010-01-01').time.year).to eq(2010)
    end

    it "should raise a no currency error if the currency does not exist" do
      expect { BigDecimal("3.25").in(:zzz) }.to raise_error(Exchange::NoCurrencyError, "zzz is not a currency nor a country code matchable to a currency")
    end
  end
end
