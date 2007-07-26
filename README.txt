[PaySimple](http://www.paysimple.com) is a payment gateway providing credit card
processing, check processing and recurring / subscription billing services.

== DESCRIPTION:

This library provides a simple interface to find, create, edit, delete, and query subscriptions
and single transactions using the PaySimple SOAP API. [PaySimple API](https://www.usaepay.com/developer/docs/beta6)


== Installation:

The simple way:
  $ sudo gem install paysimple

Directly from repository:
  $ svn co svn://svn.roundhaus.com/daikini/plugins/paysimple

== Requirements:

* soap4r 1.5.6 or higher

== Configuration:

When you signup for a PaySimple account you can setup a source key and optionally a pin and client ip address.
These are your credentials when using the PaySimple API.

	PaySimple.source = "My API Source Key Name"
  PaySimple.key = "123456"
  PaySimple.pin = "topsecret"
  PaySimple.client_ip = "192.168.0.1"


== Usage:

  require 'paysimple'

  # Bill Jennifer $12.00 monthly
  begin
    customer_number = PaySimple::Subscription.create(
      :CustomerID => 12345,
      :BillingAddress => {
        :FirstName => "Jennifer",
        :LastName => "Smith"
      },
      :CreditCardData => {
        :CardNumber => '4444555566667779',
        :CardExpiration => '0908'
      },
      :Schedule => :monthly,
      :Next => "2008-09-05",
      :Amount => 12.00
    )

    puts "Subscription created with Customer Number: #{customer_number}"
  rescue Exception => e
    puts "An error occurred: #{e.message}"
  end


  # Update subscription to use new credit card
  begin
    customer_number = 12345
    response = PaySimple::Subscription.update(
      customer_number,
      :CreditCardData => {
        :CardNumber => '4444555566667779',
        :CardExpiration => '0908'
      }
    )

    puts "Subscription updated"
  rescue Exception => e
    puts "An error occurred: #{e.message}"
  end


  # Delete subscription
  begin
    customer_number = 12345
    response = PaySimple::Subscription.delete(customer_number)

    puts "Subscription removed from active use."
  rescue Exception => e
    puts "An error occurred: #{e.message}"
  end


  # Find an existing subscription
  begin
    customer_number = 12345
    customer = PaySimple::Subscription.find(customer_number)

    puts "Found subscription for #{customer["BillingAddress"]["FirstName"], customer["BillingAddress"]["LastName"]].join(" ")}"
  rescue Exception => e
    puts "An error occurred: #{e.message}"
  end


  # Process one-time sale against existing subscription
  begin
    customer_number = 12345
    response = PaySimple::Subscription.charge(customer_number, :Amount => 34.56)

    if response['Response'] == "Approved"
      puts "One-time charge successful."
    else
      puts "An error occurred: #{response['Error']}"
    end
  rescue Exception => e
    puts "An error occurred: #{e.message}"
  end


  # Search for transactions
  begin
    response = PaySimple::Subscription.query(
      [ 
        { :Field => 'amount', :Type => 'gt', :Value => '5.0' }
      ]
    )

    response.transactions.each do |transaction|
      puts "CustomerID = #{transaction['CustomerID']}, Amount = #{transaction['Details']['Amount']}"
    end
  rescue Exception => e
    puts "An error occurred: #{e.message}"
  end


  # Bill Jennifer $12.00
  begin
    transaction = PaySimple::Transaction.create(
      :CustomerID => 12345,
      :AccountHolder => "Jennifer Smith",
      :CreditCardData => {
        :CardNumber => "4444555566667779,
        :CardExpiration => "0908"
      },
      :Details => {
        :Amount => 12.00
      }
    )
  
    puts "Sale transaction created with Reference Number: #{transaction["RefNum"]}"
  rescue Exception => e
    puts "An error occurred: #{e.message}"
  end
  
  
  # Credit Jennifer $12.00
  begin
    transaction = PaySimple::Transaction.create(
      :CustomerID => 12345,
      :AccountHolder => "Jennifer Smith",
      :CreditCardData => {
        :CardNumber => "4444555566667779,
        :CardExpiration => "0908"
      },
      :Details => {
        :Amount => -12.00
      }
    )
  
    puts "Credit transaction created with Reference Number: #{transaction["RefNum"]}"
  rescue Exception => e
    puts "An error occurred: #{e.message}"
  end
  
  
  # Void an unsettled transaction 
  begin
    reference_number = 12345
    result = PaySimple::Transaction.void(reference_number)
    
    if result
      puts "Transaction was voided"
    else
      puts "Unable to void transaction"
    end
  rescue Exception => e
    puts "An error occurred: #{e.message}"
  end
  
  
  # Find an existing transaction 
  begin
    reference_number = 12345
    transaction = PaySimple::Transaction.find(reference_number)
    
    puts "Found transaction"
  rescue Exception => e
    puts "An error occurred: #{e.message}"
  end
  
== LICENSE:

paysimple is licensed under the MIT License.

Copyright (c) 2007 [Jonathan Younger], released under the MIT license

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

