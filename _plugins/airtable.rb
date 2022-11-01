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
    e[:comienzo] = DateTime.parse(e[:comienzo]).new_offset("-03:00") if e[:comienzo]
    e[:fin] = DateTime.parse(e[:fin]).new_offset("-03:00") if e[:fin]
  }
  expanded = []
  data.each do |e|
    if e[:comienzo].to_date < e[:fin].to_date
      # si el evento dura muchos días, hacemos una nueva entrada por cada día,
      # con la hora de comienzo del primer día y la hora de fin del último día
      (e[:comienzo] .. e[:fin]).each do |comienzo|
        e2 = e.dup
        e2[:comienzo] = DateTime.new(comienzo.year, comienzo.month, comienzo.day, 
                                   e[:comienzo].hour,  e[:comienzo].min,  e[:comienzo].sec,  e[:comienzo].zone)
        e2[:fin] = DateTime.new(comienzo.year, comienzo.month, comienzo.day, 
                                   e[:fin].hour,  e[:fin].min,  e[:fin].sec,  e[:fin].zone)
        e2[:multiday] = [e[:comienzo], e[:fin]]

        expanded << e2
      end
    else
      expanded << e
    end
  end 

  grouped = expanded.
    group_by{|d| d[:comienzo].to_date.to_time}. #group by Event date
    to_a.
    map{|date, items|
      [date, items.sort_by{|d| d[:comienzo]}] # sort Events by time asc
  }
  file.write(warning, grouped.to_yaml)
end
