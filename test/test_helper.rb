#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift File.expand_path('..', __FILE__)

begin
  require 'rubygems'
  require 'bundler'
  Bundler.setup
rescue LoadError => e
  puts "Error loading bundler (#{e.message}): \"gem install bundler\" for bundler support."
end

require 'minitest'
require 'minitest/autorun'
require 'minitest/pride'
require 'money'
require 'mocha/version'
if Gem::Requirement.new('< 0.12').satisfied_by?(Gem::Version.new(Mocha::VERSION))
  require 'mocha'
else
  require 'mocha/setup'
end
require 'yaml'
require 'json'
require 'active_merchant'
require 'comm_stub'
require 'assert_equal_xml'

require 'active_support/core_ext/integer/time'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/hash/slice'

# rubocop:disable Lint/HandleExceptions
begin
  require 'active_support/core_ext/time/acts_like'
rescue LoadError
end
# rubocop:enable Lint/HandleExceptions

begin
  gem 'actionpack'
rescue LoadError
  raise StandardError, 'The view tests need ActionPack installed as gem to run'
end

require 'action_controller'
require 'action_view'
begin
  require 'active_support/core_ext/module/deprecation'
  require 'action_dispatch/testing/test_process'
rescue LoadError
  require 'action_controller/test_process'
end
require 'active_merchant/billing/integrations/action_view_helper'

ActiveMerchant::Billing::Base.mode = :test

if ENV['DEBUG_ACTIVE_MERCHANT'] == 'true'
  require 'logger'
  ActiveMerchant::Billing::Gateway.logger = Logger.new(STDOUT)
  ActiveMerchant::Billing::Gateway.wiredump_device = STDOUT
end

# Test gateways
class SimpleTestGateway < ActiveMerchant::Billing::Gateway
end

class SubclassGateway < SimpleTestGateway
end

module ActiveMerchant
  module Assertions
    def assert_field(field, value)
      clean_backtrace do
        assert_equal value, @helper.fields[field]
      end
    end

    # A handy little assertion to check for a successful response:
    #
    #   # Instead of
    #   assert_success response
    #
    #   # DRY that up with
    #   assert_success response
    #
    # A message will automatically show the inspection of the response
    # object if things go afoul.
    def assert_success(response)
      clean_backtrace do
        assert response.success?, "Response failed: #{response.inspect}"
      end
    end

    # The negative of +assert_success+
    def assert_failure(response)
      clean_backtrace do
        refute response.success?, "Response expected to fail: #{response.inspect}"
      end
    end

    def assert_valid(validateable)
      clean_backtrace do
        assert validateable.valid?, 'Expected to be valid'
      end
    end

    def assert_not_valid(validateable)
      clean_backtrace do
        refute validateable.valid?, 'Expected to not be valid'
      end
    end

    def assert_deprecation_warning(message, target)
      target.expects(:deprecated).with(message)
      yield
    end

    def assert_no_deprecation_warning(target)
      target.expects(:deprecated).never
      yield
    end

    private

    def clean_backtrace(&_block)
      yield
    rescue MiniTest::Assertion => e
      path = File.expand_path(__FILE__)
      raise MiniTest::Assertion, e.message, e.backtrace.reject { |line| File.expand_path(line) =~ /#{path}/ }
    end
  end

  module Fixtures
    HOME_DIR = RUBY_PLATFORM =~ /mswin32/ ? ENV['HOMEPATH'] : ENV['HOME'] unless defined?(HOME_DIR)
    LOCAL_CREDENTIALS = File.join(HOME_DIR.to_s, '.active_merchant/fixtures.yml') unless defined?(LOCAL_CREDENTIALS)
    DEFAULT_CREDENTIALS = File.join(File.dirname(__FILE__), 'fixtures.yml') unless defined?(DEFAULT_CREDENTIALS)

    private

    def credit_card(number = '4242424242424242', options = {})
      defaults = {
        number: number,
        month: 9,
        year: Time.now.year + 1,
        first_name: 'Longbob',
        last_name: 'Longsen',
        verification_value: '123',
        brand: 'visa'
      }.update(options)

      Billing::CreditCard.new(defaults)
    end

    def check(options = {})
      defaults = {
        name: 'Jim Smith',
        bank_name: 'Bank of Elbonia',
        routing_number: '244183602',
        account_number: '15378535',
        account_holder_type: 'personal',
        account_type: 'checking',
        number: '1'
      }.update(options)

      Billing::Check.new(defaults)
    end

    def address(options = {})
      {
        name: 'Jim Smith',
        address1: '1234 My Street',
        address2: 'Apt 1',
        company: 'Widgets Inc',
        city: 'Ottawa',
        state: 'ON',
        zip: 'K1C2N6',
        country: 'CA',
        phone: '(555)555-5555',
        fax: '(555)555-6666'
      }.update(options)
    end

    # rubocop:disable Style/ClassVars
    def all_fixtures
      @@fixtures ||= load_fixtures
    end
    # rubocop:enable Style/ClassVars

    def fixtures(key)
      data = all_fixtures[key] || raise(StandardError, "No fixture data was found for '#{key}'")

      data.dup
    end

    def load_fixtures
      [DEFAULT_CREDENTIALS, LOCAL_CREDENTIALS].each_with_object({}) do |file_name, credentials|
        if File.exist?(file_name)
          yaml_data = YAML.safe_load(File.read(file_name))
          credentials.merge!(symbolize_keys(yaml_data))
        end
        credentials
      end
    end

    def symbolize_keys(hash)
      return unless hash.is_a?(Hash)

      hash.symbolize_keys!
      hash.each { |_k, v| symbolize_keys(v) }
    end
  end
end

Minitest::Test.class_eval do
  include ActiveMerchant::Billing
  include ActiveMerchant::Assertions
  include ActiveMerchant::Utils
  include ActiveMerchant::Fixtures
end

module ActionViewHelperTestHelper
  def self.included(base)
    base.send(:include, ActiveMerchant::Billing::Integrations::ActionViewHelper)
    base.send(:include, ActionView::Helpers::FormHelper)
    base.send(:include, ActionView::Helpers::FormTagHelper)
    base.send(:include, ActionView::Helpers::UrlHelper)
    base.send(:include, ActionView::Helpers::TagHelper)
    base.send(:include, ActionView::Helpers::CaptureHelper)
    base.send(:include, ActionView::Helpers::TextHelper)
    base.send(:attr_accessor, :output_buffer)
  end

  def setup
    @controller = Class.new do
      attr_reader :url_for_options
      def url_for(options, *_parameters_for_method_reference)
        @url_for_options = options
      end
    end
    @controller = @controller.new
    @output_buffer = ''
  end

  protected

  def protect_against_forgery?
    false
  end
end
