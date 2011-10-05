# Scans a directory for gzipped iTunes connect reports and processes
# them for curl upload to Ducksboard
#
# Usage: ruby #{$0} path/to/dir currency_code

require 'money'
require 'money/bank/google_currency'
require 'json'

# Settings for currency conversion
MultiJson.engine = :json_gem
Money.default_bank = Money::Bank::GoogleCurrency.new

def log(message)
  STDERR.puts message
end

def report_to_hashes(file)
  lines = IO.readlines(file).map { |line| line.strip }
  headers = lines.shift.split("\t")

  lines.map do |line|
    entry = {}
    cols = line.strip.split("\t")
    headers.zip(cols).each { |x| entry[x[0]] = x[1] }
    
    entry
  end
end

def hash_to_currency(hash,currency)
  n = (hash["Developer Proceeds"].to_f * hash["Units"].to_i).to_money(hash["Currency of Proceeds"].to_sym)
  n.exchange_to(currency).to_f
end

dir = ARGV.shift
currency = ARGV.shift

Dir.glob(File.join(dir,"*.txt.gz")) do |file|
  date = File.basename(file).split("_")[3]
  archive_base = File.join(dir,date)
  if not File.exists?("#{archive_base}.gbp")
    # Unzip
    if not File.exists?(file.gsub(".gz",""))
      log "Inflating #{file}" 
      `gunzip #{file}`
    end  
    file.gsub!(".gz","")
  
    # Process
    log "Reading #{file}"
    entries = report_to_hashes(file)
  
    # Recompressing
    log "Recompressing"
    `gzip #{file}`
  
    # Computing
    log "Processing"
    revenue = entries.inject(0) { |sum,hash| sum += hash_to_currency(hash,currency.to_sym) }
    units = entries.inject(0) { |sum,hash| sum += (hash["Customer Price"].to_f > 0 ? hash["Units"].to_i : 0) }
  
    fout = File.open("#{archive_base}.#{currency}",'w')
    fout.puts revenue
    fout.close
    
    fout = File.open("#{archive_base}.units",'w')
    fout.puts units
    fout.close
  end
end