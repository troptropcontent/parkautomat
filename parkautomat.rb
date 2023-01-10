require 'parking_ticket'
require 'active_record'
require 'dotenv/load'

# Database
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: 'parkautomat_database.db'
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
  puts "🔎 Looking for a ticket in the database"
  Ticket.find_by(ends_on: Time.now..)
end

def current_ticket_in_client
  puts "🔎 Looking for a current ticket in the client"
  ParkingTicket.current_ticket
end

def save_ticket(ticket_attributes)
  puts "✅ A ticket that expires on #{new_ticket["ends_on"]} have been found in the client, saving it to the database."
  Ticket.create(new_ticket)
end

def renew_ticket
  puts "❌ No ticket found in the client, renewing ticket."
  ParkingTicket.renew
end


if ticket = current_ticket_in_database
  puts "✅ A ticket have been found in the database, it expires on #{ticket.ends_on}"
else
  puts "❌ No ticket found in the database"
  (ticket_attributes = current_ticket_in_client) ? save_ticket(ticket_attributes) : renew_ticket
end

