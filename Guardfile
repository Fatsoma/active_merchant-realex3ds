guard :minitest do
  watch(%r{^lib/active_merchant/billing/(.*/)?([^/]+)\.rb$}) do |m|
    "test/unit/#{m[1]}#{m[2]}_test.rb"
  end
  watch(%r{^test/unit/(.*/)?(.*)_test\.rb$})
  watch(%r{^test/test_helper\.rb$}) { 'test/unit' }
end
