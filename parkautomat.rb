require 'parking_ticket'
require 'active_record'
require 'dotenv/load'
require 'optparse'
require 'logger'

# handle command line options
options = {}
OptionParser.new do |opts|
  opts.on('-e', '--execute', 'Execute the script') do |_v|
    options[:execute] = true
  end
end.parse!

#setup a logger
@logger = Logger.new('log/parkautomat.log')

# Database
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: 'parkautomat_database.db'
)

# ParkingTicket

@parking_ticket = ParkingTicket::Base.new(
  'pay_by_phone',
  {
    username: ENV['PARKING_TICKET_USERNAME'],
    password: ENV['PARKING_TICKET_PASSWORD'],
    license_plate: ENV['PARKING_TICKET_LICENSEPLATE'],
    zipcode: ENV['PARKING_TICKET_ZIPCODE'],
    card_number: ENV['PARKING_TICKET_CARDNUMBER']
  }
)
# Creates the tickets table if it does not exists
class CreateUserTable < ActiveRecord::Migration[7.0]
  def change
    create_table :tickets do |table|
      table.datetime :starts_on
      table.datetime :ends_on
      table.float :cost
      table.string :license_plate
      table.string :client
      table.string :client_ticket_id
      table.timestamps
    end
  end
end

CreateUserTable.migrate(:up) unless ActiveRecord::Base.connection.table_exists?(:tickets)

# Ticket model backed by the previous table
class Ticket < ActiveRecord::Base
end

def current_ticket_in_database
  @logger.info("🔎 Looking for a ticket in the database")
  Ticket.find_by(ends_on: Time.now..)
end

def current_ticket_in_client
  @logger.info("🔎 Looking for a current ticket in the client")
  @parking_ticket.current_ticket
end

def save_ticket(ticket_attributes)
  @logger.info("✅ A ticket that expires on #{ticket_attributes[:ends_on]} have been found in the client, saving it to the database.")
  Ticket.create(ticket_attributes)
end

def renew_ticket
  @logger.info("❌ No ticket found in the client, renewing ticket.")
  @parking_ticket.renew
end

def execute
  if ticket = current_ticket_in_database
    @logger.info("✅ A ticket have been found in the database, it expires on #{ticket.ends_on}") 
  else 
    @logger.info("❌ No ticket found in the database")
    (ticket_attributes = current_ticket_in_client) ? save_ticket(ticket_attributes) : renew_ticket
  end
end

execute if options[:execute]
