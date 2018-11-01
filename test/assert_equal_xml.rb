require 'equivalent-xml'

def assert_equal_xml(str_1, str_2, message = nil)
  message ||= "XML not equal, expected \"#{str_2.inspect}\" but got \"#{str_1.inspect}\""

  assert(EquivalentXml.equivalent?(str_1, str_2), message)
end
