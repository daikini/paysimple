require 'rubygems'
gem 'soap4r', '>= 1.5.6' # 1.5.6 or higher
require 'soap/wsdlDriver' 
require 'digest/sha1'

# [PaySimple](http://www.paysimple.com) is a payment gateway providing credit card
# processing, check processing and recurring / subscription billing services.
#
# This library provides a simple interface to find, create, edit, delete, and query subscriptions
# and single transactions using the PaySimple SOAP API. [PaySimple API](https://www.usaepay.com/developer/docs/beta6)
#
# == Installation
#
# The simple way:
#   $ sudo gem install paysimple
#
# Directly from repository:
#   $ ./script/plugin install svn://svn.roundhaus.com/daikini/plugins/paysimple
#
# Directly from repository using piston:
#   $ piston import svn://svn.roundhaus.com/daikini/plugins/paysimple vendor/plugins/paysimple
#
# == Configuration
#
# When you signup for a PaySimple account you can setup a source key and optionally a pin and client ip address.
# These are your credentials when using the PaySimple API.
#
#   PaySimple.source = "My API Source Key Name"
#   PaySimple.key = "123456"
#   PaySimple.pin = "topsecret"
#   PaySimple.client_ip = "192.168.0.1"
#
class PaySimple
  VERSION = "1.1.0"
  WSDL_URL = File.dirname(__FILE__) + '/usaepay.wsdl'
  
  class << self
    attr_accessor :source, :key, :pin, :client_ip
  end
  self.key = "TestMerchant"
  
  class Subscription
    class << self
      # # Bill Jennifer $12.00 monthly
      # begin
      #   customer_number = PaySimple::Subscription.create(
      #     :CustomerID => 12345,
      #     :BillingAddress => {
      #       :FirstName => "Jennifer",
      #       :LastName => "Smith"
      #     },
      #     :CreditCardData => {
      #       :CardNumber => "4444555566667779",
      #       :CardExpiration => "0908"
      #     },
      #     :Schedule => :monthly,
      #     :Next => "2008-09-05",
      #     :Amount => 12.00
      #   )
      # 
      #   puts "Subscription created with Customer Number: #{customer_number}"
      # rescue Exception => e
      #   puts "An error occurred: #{e.message}"
      # end
      def create(options)
        PaySimple.send_request(:addCustomer, { :Source => PaySimple.source, :NumLeft => 0, :Enabled => true }.merge(options))
      end
      
      # # Update subscription to use new credit card
      # begin
      #   customer_number = 12345
      #   response = PaySimple::Subscription.update(
      #     customer_number,
      #     :CreditCardData => {
      #       :CardNumber => "4444555566667779",
      #       :CardExpiration => "0908"
      #     }
      #   )
      #     
      #   puts "Subscription updated"
      # rescue Exception => e
      #   puts "An error occurred: #{e.message}"
      # end
      def update(customer_number, options)
        customer = find(customer_number)
        options = PaySimple.symbolize_hash(options)
        
        # Add the existing customer properties to the options hash unless they already exist
        [
          :CustomerID,
          :SendReceipt, 
          :ReceiptNote, 
          :Notes, 
          :User, 
          :Source, 
          :Schedule, 
          :Next, 
          :NumLeft, 
          :Amount, 
          :Enabled, 
          :CustomData, 
          :Description, 
          :OrderID
        ].each do |property|
          options[property] = customer[property.to_s] unless options.has_key?(property)
        end
        
        # Add the existing customer address properties to the options hash unless they already exist
        options[:BillingAddress] ||= {}
        [
          :FirstName,
          :LastName,
          :Company,
          :Street,
          :Street2,
          :City,
          :State,
          :Zip,
          :Country,
          :Phone,
          :Fax,
          :Email
        ].each do |property|
          options[:BillingAddress][property] = customer["BillingAddress"][property.to_s] unless options[:BillingAddress].has_key?(property)
        end
        
        # Add the existing customer credit card properties to the options hash unless they already exist
        options[:CreditCardData] ||= {}
        [
          :CardNumber,
          :CardExpiration,
          :CardCode,
          :AvsStreet,
          :AvsZip,
          :CardPresent,
          :MagStripe,
          :TermType,
          :MagSupport,
          :XID,
          :CAVV,
          :ECI,
          :InternalCardAuth,
          :Pares
        ].each do |property|
          options[:CreditCardData][property] = customer["CreditCardData"][property.to_s] unless options[:CreditCardData].has_key?(property)
        end
        
        # Add the existing customer check properties to the options hash unless they already exist
        options[:CheckData] ||= {}
        [
          :CheckNumber,
          :Routing,
          :Account,
          :SSN,
          :DriversLicense,
          :DriversLicenseState
        ].each do |property|
          options[:CheckData][property] = customer["CheckData"][property.to_s] unless options[:CheckData].has_key?(property)
        end
        
        PaySimple.send_request(:updateCustomer, customer_number, options)
      end
      
      # # Delete subscription
      # begin
      #   customer_number = 12345
      #   response = PaySimple::Subscription.delete(customer_number)
      # 
      #   puts "Subscription removed from active use."
      # rescue Exception => e
      #   puts "An error occurred: #{e.message}"
      # end
      def delete(customer_number)
        PaySimple.send_request(:deleteCustomer, customer_number)
      end
    
      # # Find an existing subscription
      # begin
      #   customer_number = 12345
      #   customer = PaySimple::Subscription.find(customer_number)
      # 
      #   puts "Found subscription for #{customer["BillingAddress"]["FirstName"], customer["BillingAddress"]["LastName"]].join(" ")}"
      # rescue Exception => e
      #   puts "An error occurred: #{e.message}"
      # end
      def find(customer_number)
        PaySimple.send_request(:getCustomer, customer_number)
      end
      
      # # Process one-time sale against existing subscription
      # begin
      #   customer_number = 12345
      #   response = PaySimple::Subscription.charge(customer_number, :Amount => 34.56)
      # 
      #   if response["Response"] == "Approved"
      #     puts "One-time charge successful."
      #   else
      #     puts "An error occurred: #{response["Error"]}"
      #   end
      # rescue Exception => e
      #   puts "An error occurred: #{e.message}"
      # end
      def charge(customer_number, options, command = "", payment_method_id = 0)
        PaySimple.send_request(:runCustomerTransaction, customer_number, options, command, payment_method_id)
      end
      
      # # Search for transactions
      # begin
      #   response = PaySimple::Subscription.query(
      #     [ 
      #       { :Field => "amount", :Type => "gt", :Value => "5.0" }
      #     ]
      #   )
      # 
      #   response.transactions.each do |transaction|
      #     puts "CustomerID = #{transaction["CustomerID"]}, Amount = #{transaction["Details"]["Amount"]}"
      #   end
      # rescue Exception => e
      #   puts "An error occurred: #{e.message}"
      # end
      def query(options)
        match_all = options.delete(:match_all)
        start = options.delete(:start) || 0
        limit = options.delete(:limit) || 100
        PaySimple.send_request(:searchTransactions, options, match_all, start, limit)
      end
    end
  end
  
  class Transaction
    class << self
      # # Bill Jennifer $12.00
      # begin
      #   transaction = PaySimple::Transaction.create(
      #     :CustomerID => 12345,
      #     :AccountHolder => "Jennifer Smith",
      #     :CreditCardData => {
      #       :CardNumber => "4444555566667779",
      #       :CardExpiration => "0908"
      #     },
      #     :Details => {
      #       :Amount => 12.00
      #     }
      #   )
      # 
      #   puts "Sale transaction created with Reference Number: #{transaction["RefNum"]}"
      # rescue Exception => e
      #   puts "An error occurred: #{e.message}"
      # end
      #
      # # Credit Jennifer $12.00
      # begin
      #   transaction = PaySimple::Transaction.create(
      #     :CustomerID => 12345,
      #     :AccountHolder => "Jennifer Smith",
      #     :CreditCardData => {
      #       :CardNumber => "4444555566667779",
      #       :CardExpiration => "0908"
      #     },
      #     :Details => {
      #       :Amount => -12.00
      #     }
      #   )
      # 
      #   puts "Credit transaction created with Reference Number: #{transaction["RefNum"]}"
      # rescue Exception => e
      #   puts "An error occurred: #{e.message}"
      # end
      def create(options)
        options = PaySimple.symbolize_hash(options)
        request_type = options[:Details][:Amount] > 0.0 ? :runSale : :runCredit
        options[:Details][:Amount] = options[:Details][:Amount].abs
        
        PaySimple.send_request(request_type, { :Source => PaySimple.source }.merge(options))
      end
      
      # # Void an unsettled transaction 
      # begin
      #   reference_number = 12345
      #   result = PaySimple::Transaction.void(reference_number)
      #   
      #   if result
      #     puts "Transaction was voided"
      #   else
      #     puts "Unable to void transaction"
      #   end
      # rescue Exception => e
      #   puts "An error occurred: #{e.message}"
      # end
      def void(reference_number)
        PaySimple.send_request(:voidTransaction, reference_number)
      end
      
      # # Find an existing transaction 
      # begin
      #   reference_number = 12345
      #   transaction = PaySimple::Transaction.find(reference_number)
      #   
      #   puts "Found transaction"
      # rescue Exception => e
      #   puts "An error occurred: #{e.message}"
      # end
      def find(reference_number)
        PaySimple.send_request(:getTransaction, reference_number)
      end
    end
  end
  
  class << self
    def symbolize_hash(hash)
      hash.inject({}) { |h,(k,v)| h[k.to_sym] = v; h }
    end
    
    def token
      seed = "#{Time.now.to_i}#{rand(999999)}"
      hash = Digest::SHA1.hexdigest([key, seed, pin].join)
      { 
        'SourceKey' => key,
        'PinHash' => {
          'Type' => "sha1",
          'Seed' => seed,
          'HashValue' => hash
        },
        'ClientIP' => client_ip
      }
    end
    
    def send_request(request, *args)
      @driver ||= SOAP::WSDLDriverFactory.new(WSDL_URL).create_rpc_driver
      @driver.send(request, token, *args)
    end
  end

end