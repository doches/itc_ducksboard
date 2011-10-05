# Look in a directory, scan for files, and updates Ducksboard
#
# Usage: ruby #{$0} path/to/dir [units|gbp] URL APIKEY

require 'date'
require 'time'
require 'json'

dir = ARGV.shift
ext = ARGV.shift
url = ARGV.shift
api = ARGV.shift

entries = []
Dir.glob(File.join(dir,"*.#{ext}")) do |file|
  date = File.basename(file).split(".").shift
  timestamp = Time.parse(DateTime.parse(Date.new(date[0..3].to_i,date[4..5].to_i,date[6..7].to_i).to_s).to_s).to_i
  value = IO.readlines(file).join("").strip.to_f
  
  entries.push( {"timestamp" => timestamp, "value" => value} )
end

entries.sort! { |a,b| a['timestamp'] <=> b['timestamp'] }

sum = 0
entries.each_with_index do |entry,index|
  sum += entry["value"]
  entries[index]["value"] = sum.to_i
end

cmd = "curl -u #{api}:ignored -d '#{entries.to_json}' #{url}"
`#{cmd}`