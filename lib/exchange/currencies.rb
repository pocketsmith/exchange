# -*- encoding : utf-8 -*-
require 'singleton'
require 'forwardable'
require 'yaml'

module Exchange

  # This class handles everything that has to do with certified formatting of
  # the different currencies. The standard is stored in the currencies YAML
  # file, based around ISO4217 it has been extended to include other currencies
  # @version 0.6
  # @since 0.3
  # @author Beat Richartz
  #
  class Currencies
    include Singleton
    extend SingleForwardable

    class << self

      private
        # @private
        # @macro [attach] install_operations

        def install_operation op
          self.class_eval <<-EOV
            def #{op} amount, currency, precision=nil, opts={}
              minor = definitions[currency][:minor_unit]
              money = amount.is_a?(BigDecimal) ? amount : BigDecimal.new(amount.to_s, precision_for(amount, currency))
              if opts[:psych] && minor > 0
                money.#{op}(0) - BigDecimal.new((1.0/(10**minor)).to_s)
              elsif opts[:psych]
                (((money.#{op}(0) / BigDecimal.new("10.0")).#{op}(0)) - BigDecimal.new("0.1")) * BigDecimal.new("10")
              else
                money.#{op}(precision || minor)
              end
            end
          EOV
        end

    end

    # The currencies that have been loaded. Use this method to get to the
    # definitions
    # They are static, so they can be stored in a class variable without many
    # worries
    # @return [Hash] The currency definitions with the currency code as keys
    #
    def definitions
      load_currencies if @iso_definitions.nil?

      @iso_definitions.merge(
        @unofficial_definitions.merge(@historical_definitions)
      )
    end

    # The currency definitions marked as iso4217
    def iso4217_definitions
      load_currencies if @iso_definitions.nil?

      @iso_definitions
    end

    # The currency definitions that have been marked as unofficial
    def unofficial_definitions
      load_currencies if @unofficial_definitions.nil?

      @unofficial_definitions
    end

    # The currency definitions that have been marked as historical (that is, they
    # have been replaced in active use)
    def historical_definitions
      load_currencies if @historical_definitions.nil?

      @historical_definitions
    end

    # The currency definitions that aren't marked as historical
    def active_definitions
      iso4217_definitions.merge(unofficial_definitions)
    end

    # The currency definitions that are supported by OXR
    def oxr_definitions
      definitions.select do |_, c|
        c[:supported_providers].include?(:oxr) if c[:supported_providers]
      end
    end

    # A map of country abbreviations to currency codes. Makes an instantiation of currency codes via a country code
    # possible
    # @return [Hash] The ISO3166 (1 and 2) country codes matched to a currency
    #
    def country_map
      @country_map ||= load_countries
    end

    # All defined currencies as an array of symbols for inclusion testing
    # @return [Array] An Array of currency symbols
    #
    def currencies
      @currencies  ||= definitions.keys.sort_by(&:to_s)
    end

    # All currencies defined by ISO 4217 as an array of symbols for inclusion
    # testing
    # Note this is implicitly only active ISO 4217 currencies
    # @return [Array] An Array of currency symbols
    #
    def iso4217_currencies
      @iso4217_currencies ||= iso4217_definitions.keys.sort_by(&:to_s)
    end

    # All unofficial defined currencies as an array of symbols for inclusion
    # testing
    # @return [Array] An Array of currency symbols
    #
    def unofficial
      @unofficial_currencies ||= unofficial_definitions.keys.sort_by(&:to_s)
    end

    # All historical defined currencies as an array of symbols for inclusion
    # testing
    # @return [Array] An Array of currency symbols
    #
    def historical_currencies
      @historical_currencies ||= historical_definitions.keys.sort_by(&:to_s)
    end

    # All active defined currencies as an array of symbols for inclusion testing
    # @return [Array] An Array of currency symbols
    #
    def active_currencies
      @active_currencies ||= active_definitions.keys.sort_by(&:to_s)
    end

    def oxr_currencies
      @oxr_currencies ||= oxr_definitions.keys.sort_by(&:to_s)
    end

    # Check if a currency is defined by ISO 4217 standards
    # @param [Symbol] currency the downcased currency symbol
    # @return [Boolean] true if the symbol matches a currency, false if not
    #
    # Note that this is also checking the country_map for the given currency!
    def defines? currency
      currencies.include?(country_map[currency] ? country_map[currency] : currency)
    end

    # Asserts a given argument is a currency. Tries to match with a country code if the argument is not a currency
    # @param [Symbol, String] arg The argument to assert
    # @return [Symbol] The matching currency as a symbol
    #
    def assert_currency! arg
      defines?(arg) ? (country_map[arg] || arg) : raise(Exchange::NoCurrencyError.new("#{arg} is not a currency nor a country code matchable to a currency"))
    end

    # Use this to instantiate a currency amount. For one, it is important that we use BigDecimal here so nothing gets lost because
    # of floating point errors. For the other, This allows us to set the precision exactly according to the iso definition
    # @param [BigDecimal, Fixed, Float, String] amount The amount of money you want to instantiate
    # @param [String, Symbol] currency The currency you want to instantiate the money in
    # @return [BigDecimal] The instantiated currency
    # @example instantiate a currency from a string
    #   Exchange::Currencies.instantiate("4523", "usd") #=> #<Bigdecimal 4523.00>
    # @note Reinstantiation is not needed in case the amount is already a big decimal. In this case, the maximum precision is already given.
    #
    def instantiate amount, currency
      if amount.is_a?(BigDecimal)
        amount
      else
        BigDecimal.new(amount.to_s, precision_for(amount, currency))
      end
    end

    # Converts the currency to a string in ISO 4217 standardized format, either with or without the currency. This leaves you
    # with no worries how to display the currency.
    # @param [BigDecimal, Fixed, Float] amount The amount of currency you want to stringify
    # @param [String, Symbol] currency The currency you want to stringify
    # @param [Hash] opts The options for formatting
    # @option opts [Boolean] :format The format to put the string out in: :amount for only the amount, :symbol for a string with a currency symbol
    # @return [String] The formatted string
    # @example Convert a currency to a string
    #   Exchange::Currencies.stringify(49.567, :usd) #=> "USD 49.57"
    # @example Convert a currency without minor to a string
    #   Exchange::Currencies.stringif(45, :jpy) #=> "JPY 45"
    # @example Convert a currency with a three decimal minor to a string
    #   Exchange::Currencies.stringif(34.34, :omr) #=> "OMR 34.340"
    # @example Convert a currency to a string without the currency
    #   Exchange::Currencies.stringif(34.34, :omr, :amount_only => true) #=> "34.340"
    #
    def stringify amount, currency, opts={}
      definition    = definitions[currency]
      separators    = definition[:separators] || {}
      format        = "%.#{definition[:minor_unit]}f"
      string        = format % amount
      major, minor  = string.split('.')

      major.gsub!(/(\d)(?=(\d\d\d)+(?!\d))/) { $1 + separators[:major] } if separators[:major] && opts[:format] != :plain

      string      = minor ? major + (opts[:format] == :plain || !separators[:minor] ? '.' : separators[:minor]) + minor : major
      pre         = [[:amount, :plain].include?(opts[:format]) && '', opts[:format] == :symbol && definition[:symbol], currency.to_s.upcase + ' '].detect{|a| a.is_a?(String)}

      "#{pre}#{string}"
    end

    # Returns the symbol for a given currency. Returns nil if no symbol is present
    # @param currency The currency to return the symbol for
    # @return [String, NilClass] The symbol or nil
    #
    def symbol currency
      definitions[currency][:symbol]
    end

    # Use this to round a currency amount. This allows us to round exactly to the number of minors the currency has in the
    # iso definition
    # @param [BigDecimal, Fixed, Float, String] amount The amount of money you want to round
    # @param [String, Symbol] currency The currency you want to round the money in
    # @example Round a currency with 2 minors
    #   Exchange::Currencies.round("4523.456", "usd") #=> #<Bigdecimal 4523.46>

    install_operation :round

    # Use this to ceil a currency amount. This allows us to ceil exactly to the number of minors the currency has in the
    # iso definition
    # @param [BigDecimal, Fixed, Float, String] amount The amount of money you want to ceil
    # @param [String, Symbol] currency The currency you want to ceil the money in
    # @example Ceil a currency with 2 minors
    #   Exchange::Currencies.ceil("4523.456", "usd") #=> #<Bigdecimal 4523.46>

    install_operation :ceil

    # Use this to floor a currency amount. This allows us to floor exactly to the number of minors the currency has in the
    # iso definition
    # @param [BigDecimal, Fixed, Float, String] amount The amount of money you want to floor
    # @param [String, Symbol] currency The currency you want to floor the money in
    # @example Floor a currency with 2 minors
    #   Exchange::Currencies.floor("4523.456", "usd") #=> #<Bigdecimal 4523.46>

    install_operation :floor

    # Forwards the assure_time method to the instance using singleforwardable
    #
    def_delegators :instance, :definitions, :instantiate, :stringify, :symbol,
      :round, :ceil, :floor, :currencies, :country_map, :defines?,
      :assert_currency!, :iso4217_definitions, :crypto_definitions,
      :historical_definitions, :active_definitions, :oxr_definitions,
      :iso4217_currencies, :crypto_currencies, :historical_currencies,
      :active_currencies, :oxr_currencies

    private

    # Load the currencies from their file, with a quick sanity check that
    # any `replaced_by` references are included in the file
    def load_currencies
      @iso_definitions = symbolize_keys(
        YAML.load_file(File.join(ROOT_PATH, 'iso4217.yml'))
      )

      @historical_definitions = symbolize_keys(
        YAML.load_file(File.join(ROOT_PATH, 'iso4217-historical.yml'))
      )

      @unofficial_definitions = symbolize_keys(
        YAML.load_file(File.join(ROOT_PATH, 'unofficial.yml'))
      )

      historical_keys = @historical_definitions.keys

      historical_keys.each do |key|
        replacement_currency = @historical_definitions[key][:replaced_by]
        if replacement_currency
          unless currencies.include?(replacement_currency)
            raise Exchange::NoCurrencyError,
              "#{replacement_currency} is not matchable to a currency"
          end
        end
      end
    end

    def load_countries
      loaded_countries = symbolize_keys(
        YAML.load_file(File.join(ROOT_PATH, 'currency_country_map.yml'))
      )

      loaded_countries.each do |k, v|
        unless currencies.include?(v)
          raise Exchange::NoCurrencyError,
            "Country #{k} maps to #{v} which is not matchable to a currency"
        end
      end
    end

    # symbolizes keys and returns a new hash
    #
    def symbolize_keys hsh
      new_hsh = Hash.new

      hsh.each_pair do |k,v|
        v = symbolize_keys v if v.is_a?(Hash)
        new_hsh[k.downcase.to_sym] = v
      end

      new_hsh
    end

    # get a precision for a specified amount and a specified currency
    #
    # @params [Float, Integer] amount The amount to get the precision for
    # @params [Symbol] currency the currency to get the precision for
    #
    def precision_for amount, currency
      defined_minor_precision                         = definitions[currency][:minor_unit]
      match                                           = amount.to_s.match(/^-?(\d*)\.?(\d*)e?(-?\d+)?$/).to_a[1..3]
      given_major_precision, given_minor_precision    = precision_from_match *match

      given_major_precision + [defined_minor_precision, given_minor_precision].max
    end

    # Get the precision from a match with /^-?(\d*)\.?(\d*)e?(-?\d+)?$/
    #
    # @params [String] major The major amount of the match as a string
    # @params [String] minor The minor amount of the match as a string
    # @params [String] rational The rational of the match as a string
    # @return [Array] An array containing the major and the minor precision in this order
    #
    def precision_from_match major, minor, rational=nil
      if rational
        leftover_minor_precision = minor.eql?('0') ? 0 : minor.size
        rational_precision       = rational.delete('-').to_i
        [major.size, leftover_minor_precision.send(rational.start_with?('-') ? :+ : :-, rational_precision)]
      else
        [major, minor].map(&:size)
      end
    end

  end
end
