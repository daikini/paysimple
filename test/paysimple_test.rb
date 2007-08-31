require 'test/unit'
require File.dirname(__FILE__) + '/../lib/paysimple.rb'
require 'base64'
require 'yaml'

PaySimple.source = ENV["PAYSIMPLE_SOURCE"]
PaySimple.key = ENV["PAYSIMPLE_KEY"]
PaySimple.pin = ENV["PAYSIMPLE_PIN"]

class PaySimpleTest < Test::Unit::TestCase
  
  def test_should_create_find_and_delete_a_subscription
    subscription_attributes = { 
      :Amount => 44.93, 
      :BillingAddress => {
        :FirstName => "John", 
        :LastName => "Doe", 
        :Company => "Acme Corp", 
        :Street => "1234 main st", 
        :Street2 => "Suite #343", 
        :City => "Los Angeles", 
        :State => "CA", 
        :Zip => "90036", 
        :Country => "US", 
        :Email => "jdoe@acme.com", 
        :Phone => "333-333-3333", 
        :Fax => "333-333-3334"
      }, 
      :CreditCardData => {
        :CardNumber => "4444555566667779", 
        :CardExpiration => "0908", 
      }, 
      :CustomData => Base64.encode64({"mydata" => "We could put anything in here!"}.to_yaml),
      :CustomerID => (123123 + rand).to_s, 
      :Description => "Weekly Bill", 
      :Enabled => true, 
      :Next => "2010-09-05", 
      :Notes => "Testing the soap addCustomer Function", 
      :NumLeft => 52, 
      :OrderID => rand.to_s, 
      :ReceiptNote => "You have been charged", 
      :Schedule => :Weekly, 
      :SendReceipt => true, 
      :User => nil 
    }
    
    assert customer_number = PaySimple::Subscription.create(subscription_attributes)
    assert subscription = PaySimple::Subscription.find(customer_number)
    assert PaySimple::Subscription.delete(customer_number)

    assert_equal subscription_attributes[:Amount], subscription["Amount"]
    
    subscription_attributes[:BillingAddress].each do |key, value|
      assert_equal value, subscription["BillingAddress"][key.to_s]
    end
    
    assert_equal "XXXXXXXXXXXX7779", subscription["CreditCardData"]["CardNumber"]
    assert_equal "XXXX", subscription["CreditCardData"]["CardExpiration"]
    assert_equal "XXX", subscription["CreditCardData"]["CardCode"]
    assert_equal subscription_attributes[:BillingAddress][:Street], subscription["CreditCardData"]["AvsStreet"]
    assert_equal subscription_attributes[:BillingAddress][:Zip], subscription["CreditCardData"]["AvsZip"]
    
    # assert_equal subscription_attributes[:CustomData], subscription["CustomData"]
    assert_equal subscription_attributes[:CustomerID], subscription["CustomerID"]
    assert_equal subscription_attributes[:Description], subscription["Description"]
    assert_equal subscription_attributes[:Enabled], subscription["Enabled"]
    assert_equal "2010-09-05T12:00:00", subscription["Next"]
    assert_equal subscription_attributes[:Notes], subscription["Notes"]
    assert_equal subscription_attributes[:NumLeft], subscription["NumLeft"]
    assert_equal subscription_attributes[:OrderID], subscription["OrderID"]
    assert_equal subscription_attributes[:ReceiptNote], subscription["ReceiptNote"]
    assert_equal subscription_attributes[:Schedule].to_s, subscription["Schedule"]
    assert_equal subscription_attributes[:SendReceipt], subscription["SendReceipt"]
    assert_equal "(Auto)", subscription["User"]
  end
end
