# -*- encoding : utf-8 -*-
module Exchange
  module ExternalAPI
    # The Open Exchange Rates API class, handling communication with the Open Source Currency bot API
    # You can find further information on the Open Exchange Rates API here: http://openexchangerates.org
    # @author Beat Richartz
    # @version 0.1
    # @since 0.1
    #
    class OpenExchangeRates < Base

      # The base of the Open Exchange Rates exchange API
      #
      API_URL              = 'openexchangerates.org/api'

      # The currencies the Open Exchange Rates API can convert
      #
      CURRENCIES           = [:aed, :afn, :all, :amd, :ang, :aoa, :ars, :aud, :awg, :azn, :bam, :bbd, :bdt, :bgn, :bhd, :bif, :bmd, :bnd, :bob, :brl, :bsd, :btc, :btn, :bwp, :byr, :bzd, :cad, :cdf, :chf, :clf, :clp, :cny, :cop, :crc, :cuc, :cup, :cve, :czk, :djf, :dkk, :dop, :dzd, :eek, :egp, :ern, :etb, :eur, :fjd, :fkp, :gbp, :gel, :ggp, :ghs, :gip, :gmd, :gnf, :gtq, :gyd, :hkd, :hnl, :hrk, :htg, :huf, :idr, :ils, :imp, :inr, :iqd, :irr, :isk, :jep, :jmd, :jod, :jpy, :kes, :kgs, :khr, :kmf, :kpw, :krw, :kwd, :kyd, :kzt, :lak, :lbp, :lkr, :lrd, :lsl, :ltl, :lvl, :lyd, :mad, :mdl, :mga, :mkd, :mmk, :mnt, :mop, :mro, :mtl, :mur, :mvr, :mwk, :mxn, :myr, :mzn, :nad, :ngn, :nio, :nok, :npr, :nzd, :omr, :pab, :pen, :pgk, :php, :pkr, :pln, :pyg, :qar, :ron, :rsd, :rub, :rwf, :sar, :sbd, :scr, :sdg, :sek, :sgd, :shp, :sll, :sos, :srd, :std, :svc, :syp, :szl, :thb, :tjs, :tmt, :tnd, :top, :try, :ttd, :twd, :tzs, :uah, :ugx, :usd, :uyu, :uzs, :vef, :vnd, :vuv, :wst, :xaf, :xag, :xau, :xcd, :xdr, :xof, :xpd, :xpf, :xpt, :yer, :zar, :zmk, :zmw, :zwl]

      # Updates the rates by getting the information from Open Exchange Rates for today or a defined historical date
      # The call gets cached for a maximum of 24 hours.
      # @param [Hash] opts Options to define for the API Call
      # @option opts [Time, String] :at a historical date to get the exchange rates for
      # @example Update the Open Exchange Rates API to use the file of March 2, 2010
      #   Exchange::ExternalAPI::OpenExchangeRates.new.update(:at => Time.gm(3,2,2010))
      #
      def update opts={}
        time = helper.assure_time(opts[:at])

        Call.new(api_url(time), :at => time, :api => self.class) do |result|
          @base                 = result['base'].downcase.to_sym
          @rates                = extract_rates(result)
          @timestamp            = result['timestamp'].to_i
        end
      end

      private

        # Helper method to extract rates from the api call result
        # @param [JSON] parsed The parsed result
        # @return [Hash] A hash with rates
        # @since 0.7
        # @version 0.7
        #
        def extract_rates parsed
          to_hash! parsed['rates'].keys.map{|k| k.downcase.to_sym }.zip(parsed['rates'].values.map{|v| BigDecimal.new(v.to_s) }).flatten
        end

        # A helper function to build an api url for either a specific time or the latest available rates
        # @param [Time] time The time to build the api url for
        # @return [String] an api url for the time specified
        # @since 0.1
        # @version 0.2.6
        #
        def api_url time=nil
          today   = Time.now
          [
            "#{config.protocol}:/",
            API_URL,
            time && (time.year != today.year || time.yday != today.yday) ? "historical/#{time.strftime("%Y-%m-%d")}.json" : "latest.json"
          ].join('/') + "?app_id=#{config.app_id}"
        end
    end
  end
end
