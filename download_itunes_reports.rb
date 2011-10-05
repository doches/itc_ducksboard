# Download iTunes Connect reports using Apple's Autoingest tool
#
# Usage: ruby #{$0} path/to/save/into itc-username itc-password itc-vendor

dir = ARGV.shift
user = ARGV.shift
pass = ARGV.shift
vend = ARGV.shift

timestamp = Time.parse(Date.today.to_s).to_i
day = 86400

`mkdir -p #{dir}`

(1..14).each do |past|
  stamp = Time.at(timestamp - (past*day))
  date = Date.parse(stamp.to_s)
  
  file = File.join(dir,"S_D_#{vend}_#{date.strftime('%Y%m%d')}.txt.gz")
  if not File.exists?(file)
    cmd = "java Autoingestion #{user} #{pass} #{vend} Sales Daily Summary #{date.strftime('%Y%m%d')}"
    puts cmd
    puts `#{cmd}`
    `mv *.txt.gz #{file}`
  else
    STDERR.puts "#{file} exists"
  end
end