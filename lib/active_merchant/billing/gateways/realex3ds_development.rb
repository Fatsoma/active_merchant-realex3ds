module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    # Realex Development Gateway
    #
    # Because the Realex gateway does not have a separate :test environment,
    # we are unable to really work with it in a development environment.
    #
    # The Bogus gateway was my initial choice for testing, however it does not take valid card data as
    # giving successful responses therefore not enabling it to work if you have significant pre-validation
    # of card data.
    #
    # Realex also expects some extra parameters and therefore I thought it better to encapsulate them all
    # here in a working development gateway that will act like Realex in production.
    #
    class RealexDevelopmentGateway < Gateway
      AUTHORIZATION = '53433'.freeze

      SUCCESSFUL_CARD = '1111111111111111'.freeze
      FAILING_CARD    = '2222222222222222'.freeze

      SUCCESS_MESSAGE = 'Realex Development Gateway: Forced success'.freeze
      FAILURE_MESSAGE = 'Realex Development Gateway: Forced failure'.freeze
      ERROR_MESSAGE = "Realex Development Gateway: Use CreditCard number #{SUCCESSFUL_CARD} for success, #{FAILING_CARD} for exception and anything else for error".freeze
      CREDIT_ERROR_MESSAGE = 'Realex Development Gateway: Use trans_id 1 for success, 2 for exception and anything else for error'.freeze
      UNSTORE_ERROR_MESSAGE = 'Realex Development Gateway: Use trans_id 1 for success, 2 for exception and anything else for error'.freeze
      CAPTURE_ERROR_MESSAGE = 'Realex Development Gateway: Use authorization number 1 for exception, 2 for error and anything else for success'.freeze
      VOID_ERROR_MESSAGE = 'Realex Development Gateway: Use authorization number 1 for exception, 2 for error and anything else for success'.freeze

      self.money_format = :cents
      self.default_currency = 'EUR'
      self.supported_cardtypes = %i[visa master american_express diners_club switch solo laser]
      self.supported_countries = %w[IE GB]
      self.homepage_url = 'http://www.realexpayments.com/'
      self.display_name = 'Realex Development'

      def authorize(money, creditcard, _options = {})
        case creditcard.number
        when SUCCESSFUL_CARD
          Response.new(true, SUCCESS_MESSAGE, { authorized_amount: money.to_s, pasref: '1234' }, test: true, authorization: AUTHORIZATION)
        when FAILING_CARD
          Response.new(false, FAILURE_MESSAGE, { authorized_amount: money.to_s, error: FAILURE_MESSAGE }, test: true)
        else
          raise Error, ERROR_MESSAGE
        end
      end

      def purchase(money, creditcard, _options = {})
        case creditcard.number
        when SUCCESSFUL_CARD
          Response.new(true, SUCCESS_MESSAGE, { paid_amount: money.to_s, pasref: '1234' }, test: true, authorization: AUTHORIZATION)
        when FAILING_CARD
          Response.new(false, FAILURE_MESSAGE, { paid_amount: money.to_s, error: FAILURE_MESSAGE }, test: true)
        else
          raise Error, ERROR_MESSAGE
        end
      end

      def credit(money, ident, _options = {})
        case ident
        when '1'
          raise Error, CREDIT_ERROR_MESSAGE
        when '2'
          Response.new(false, FAILURE_MESSAGE, { paid_amount: money.to_s, error: FAILURE_MESSAGE }, test: true)
        else
          Response.new(true, SUCCESS_MESSAGE, { paid_amount: money.to_s, orderid: '1234' }, test: true)
        end
      end

      def capture(money, ident, _options = {})
        case ident
        when '1'
          raise Error, CAPTURE_ERROR_MESSAGE
        when '2'
          Response.new(false, FAILURE_MESSAGE, { paid_amount: money.to_s, error: FAILURE_MESSAGE }, test: true)
        else
          Response.new(true, SUCCESS_MESSAGE, { paid_amount: money.to_s }, test: true)
        end
      end

      def void(ident, _options = {})
        case ident
        when '1'
          raise Error, VOID_ERROR_MESSAGE
        when '2'
          Response.new(false, FAILURE_MESSAGE, { authorization: ident, error: FAILURE_MESSAGE }, test: true)
        else
          Response.new(true, SUCCESS_MESSAGE, { authorization: ident }, test: true)
        end
      end

      def store(creditcard, _options = {})
        case creditcard.number
        when SUCCESSFUL_CARD
          Response.new(true, SUCCESS_MESSAGE, { billingid: '1' }, test: true, authorization: AUTHORIZATION)
        when FAILING_CARD
          Response.new(false, FAILURE_MESSAGE, { billingid: nil, error: FAILURE_MESSAGE }, test: true)
        else
          raise Error, ERROR_MESSAGE
        end
      end

      def unstore(_creditcard, _options = {})
        Response.new(true, SUCCESS_MESSAGE, { billingid: '1' }, test: true, authorization: AUTHORIZATION)
      end

      def store_user(_options = {})
        Response.new(true, SUCCESS_MESSAGE, { billingid: '1' }, test: true, authorization: AUTHORIZATION)
      end
    end
  end
end
