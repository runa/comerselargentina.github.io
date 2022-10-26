require 'dotenv/load'
require 'airtable'
require 'active_support/all'
require 'time'

raise "Missing ENV['AIRTABLE_API_KEY']" if not ENV['AIRTABLE_API_KEY']
raise "Missing ENV['AIRTABLE_TABLE']" if not ENV['AIRTABLE_TABLE']
raise "Missing ENV['AIRTABLE_BASE']" if not ENV['AIRTABLE_BASE']
airtable = Airtable::Client.new(ENV['AIRTABLE_API_KEY'])
table = airtable.table(ENV['AIRTABLE_BASE'], ENV['AIRTABLE_TABLE'])

File.open("_data/#{ENV['AIRTABLE_TABLE']}.yml", 'w') do |file|
  data = table.records(:sort => ["Comienzo", :desc]).map(&:attributes)
  warning = "# Do not edit this file manually \n"
  data.each{|e|
    e[:comienzo] = DateTime.parse(e[:comienzo]) if e[:comienzo]
    e[:fin] = DateTime.parse(e[:fin]) if e[:fin]
  }
  data = data.
    group_by{|d| d[:comienzo].to_date.to_time}. #group by Event date
    to_a.
    map{|date, items|
      [date, items.sort_by{|d| d[:comienzo]}] # sort Events by time asc
  }
  file.write(warning, data.to_yaml)
end
