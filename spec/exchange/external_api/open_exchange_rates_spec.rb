# -*- encoding : utf-8 -*-
require 'spec_helper'

describe "Exchange::ExternalAPI::OpenExchangeRates" do
  let(:oxr_path) { "http://openexchangerates.org:443/api" }
  let(:test_url) { "#{oxr_path}/latest.json?app_id=" }
  let(:test_response) { fixture('api_responses/example_json_api.json') }
  let(:test_hist_url) { "#{oxr_path}/historical/2011-09-09.json?app_id=" }

  before(:all) do
    Exchange.configuration = Exchange::Configuration.new{|c|
      c.cache = {
        :subclass => :no_cache
      }
      c.api = {
        :subclass => :open_exchange_rates,
        :protocol => :https
      }
    }
  end

  after(:all) do
    Exchange.configuration.reset
  end

  describe "updating rates" do
    subject { Exchange::ExternalAPI::OpenExchangeRates.new }

    before(:each) do
      stub_request(:get, test_url).to_return(body: test_response)
    end

    it "should call the api and yield a block with the result" do
      subject.update

      expect(subject.base).to eq(:usd)

      expect(a_request(:get, test_url)).to have_been_made.times(1)
    end

    it "should set a unix timestamp from the api file" do
      subject.update

      expect(subject.timestamp).to eq(1327748496)

      expect(a_request(:get, test_url)).to have_been_made.times(1)
    end
  end

  describe "conversion" do
    subject { Exchange::ExternalAPI::OpenExchangeRates.new }

    before(:each) do
      stub_request(:get, test_url).to_return(body: test_response)
    end

    it "should convert right" do
      expect(subject.convert(78, :eur, :usd).round(2)).
        to eq(BigDecimal("103.12"))

      expect(a_request(:get, test_url)).to have_been_made.times(1)
    end

    it "should convert negative numbers right" do
      expect(subject.convert(-70, :chf, :usd).round(2)).
        to eq(BigDecimal("-76.71"))

      expect(a_request(:get, test_url)).to have_been_made.times(1)
    end

    it "should convert when given symbols" do
      expect(subject.convert(70, :sek, :usd).round(2)).to eq(10.38)

      expect(a_request(:get, test_url)).to have_been_made.times(1)
    end
  end

  describe "historic conversion" do
    subject { Exchange::ExternalAPI::OpenExchangeRates.new }

    it "should convert and be able to use history" do
      stub_request(:get, test_hist_url).to_return(body: test_response)

      expect(subject.convert(72, :eur, :usd, :at => Time.gm(2011,9,9)).round(2)).
        to eq(BigDecimal("95.19"))

      expect(a_request(:get, test_hist_url)).to have_been_made.times(1)
    end

    it "should convert negative numbers right" do
      stub_request(:get, test_hist_url).to_return(body: test_response)

      expect(subject.convert(-70, :chf, :usd, :at => Time.gm(2011,9,9)).round(2)).
        to eq(BigDecimal("-76.71"))

      expect(a_request(:get, test_hist_url)).to have_been_made.times(1)
    end

    it "should convert when given symbols" do
      stub_request(:get, test_hist_url).to_return(body: test_response)

      expect(subject.convert(70, :sek, :usd, :at => Time.gm(2011,9,9)).round(2)).
        to eq(10.38)

      expect(a_request(:get, test_hist_url)).to have_been_made.times(1)
    end

    it "should convert right when the year is the same, but the yearday is not" do
      url = "#{oxr_path}/historical/#{Time.now.year}-#{'0' if Time.now.month < 11}#{Time.now.month > 9 ? Time.now.month - 1 : Time.now.month + 1}-01.json?app_id="

      stub_request(:get, url).to_return(body: test_response)

      expect(subject.convert(70, :sek, :usd, :at => Time.gm(Time.now.year,Time.now.month > 9 ? Time.now.month - 1 : Time.now.month + 1,1)).round(2)).to eq(10.38)

      expect(a_request(:get, url)).to have_been_made.times(1)
    end

    it "should convert right when the yearday is the same, but the year is not" do
      url = "http://openexchangerates.org:443/api/historical/#{Time.now.year-1}-03-01.json?app_id="

      stub_request(:get, url).to_return(body: test_response)

      expect(subject.convert(70, :sek, :usd, :at => Time.gm(Time.now.year - 1,3,1)).round(2)).to eq(10.38)

      expect(a_request(:get, url)).to have_been_made.times(1)
    end
  end
end
