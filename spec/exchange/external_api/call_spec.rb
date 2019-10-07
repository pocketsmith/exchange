# -*- encoding : utf-8 -*-
require 'spec_helper'

describe "Exchange::ExternalAPI::Call" do
  before(:all) do
    Exchange.configuration = Exchange::Configuration.new{|c|
      c.cache = {
        :subclass => :no_cache
      }
    }
  end

  after(:all) do
    Exchange.configuration.reset
  end

  let(:fake_blank_url) { "http://BLANK_API" }
  let(:fake_json_url) { "http://JSON_API" }
  let(:fake_xml_url) { "http://XML_API" }
  let(:json_response) { fixture('api_responses/example_json_api.json') }
  let(:xml_response) { fixture('api_responses/example_ecb_xml_90d.xml') }

  describe "initialization" do
    context "with a json api" do
      it "should call the api and yield a block with the result" do
        stub_request(:get, fake_json_url).to_return(body: json_response)

        Exchange::ExternalAPI::Call.new(fake_json_url) do |result|
          expect(result).to eq(JSON.load(json_response))
        end
      end

      context "with http errors" do
        it "should recall and deliver the result if possible" do
          stub_request(:get, fake_json_url).
            to_return(body: "URI", status: 404).times(2).then.
            to_return(body: json_response)

          Exchange::ExternalAPI::Call.new(fake_json_url) do |result|
            expect(result).to eq(JSON.load(json_response))
          end

          expect(a_request(:get, fake_json_url)).to have_been_made.times(3)
        end

        it "should raise if the maximum recall size is reached" do
          stub_request(:get, fake_json_url).
            to_return(body: "URI", status: 404).times(7)

          expect { Exchange::ExternalAPI::Call.new(fake_json_url) }.
            to raise_error(Exchange::ExternalAPI::APIError)

          expect(a_request(:get, fake_json_url)).to have_been_made.times(7)
        end
      end

      context "with socket errors" do
        it "should raise an error immediately" do
          stub_request(:get, fake_json_url).to_timeout

          expect { Exchange::ExternalAPI::Call.new(fake_json_url) }.
            to raise_error(Exchange::ExternalAPI::APIError)
        end
      end
    end
  end

  context "with an xml api" do
    it "should call the api and yield a block with the result" do
      stub_request(:get, fake_xml_url).to_return(body: xml_response)

      Exchange::ExternalAPI::Call.new(fake_xml_url, :format => :xml) do |result|
        expect(result.to_s).
          to eq(Nokogiri::XML.
            parse(fixture('api_responses/example_ecb_xml_90d.xml').
            sub("\n", '')).to_s
          )
      end
    end

    context "with http errors" do
      it "should recall and deliver the result if possible" do
          stub_request(:get, fake_xml_url).
            to_return(body: "URI", status: 404).times(2).then.
            to_return(body: xml_response)

        Exchange::ExternalAPI::Call.new(fake_xml_url, :format => :xml) do |result|
          expect(result.to_s).
            to eq(Nokogiri::XML.
              parse(fixture('api_responses/example_ecb_xml_90d.xml').
              sub("\n", '')).to_s
          )
        end
      end

      it "should raise if the maximum recall size is reached" do
        stub_request(:get, fake_xml_url).
          to_return(body: "URI", status: 404).times(7)

        expect { Exchange::ExternalAPI::Call.new(fake_xml_url) }.
          to raise_error(Exchange::ExternalAPI::APIError)

        expect(a_request(:get, fake_xml_url)).to have_been_made.times(7)
      end
    end

    context "with socket errors" do
      it "should raise an error immediately" do
        stub_request(:get, fake_xml_url).to_timeout

        expect { Exchange::ExternalAPI::Call.new(fake_xml_url, :format => :xml) }.
          to raise_error(Exchange::ExternalAPI::APIError)
      end
    end
  end

  context "with an api returning blank responses" do
    before(:each) { stub_request(:get, fake_blank_url).to_return(body: "") }

    it "should raise an error" do
      expect { Exchange::ExternalAPI::Call.new(fake_blank_url) }.
        to raise_error(Exchange::ExternalAPI::APIError, /blank/)
    end
  end
end
