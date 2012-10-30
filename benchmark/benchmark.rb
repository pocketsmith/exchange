require 'benchmark'
require 'bigdecimal'

class Helper
  def load_or_omit a_gem
    begin
      require a_gem.to_s
      return true
    rescue LoadError => e
      puts "You do not have #{a_gem} installed. gem install #{a_gem} to benchmark it\n\n"
      return false
    end
  end
  
  def median array
    (array.inject(0) { |sum, member| sum += member } / 3.0).round 6 if array
  end
end

helper = Helper.new

operations = 1000
results = {}

results[:normal_float] = []
3.times { results[:normal_float] << Benchmark.realtime { operations.times { 3.555 * 4.234 } } }

results[:big_decimal] = []
one = BigDecimal.new("3.555")
two = BigDecimal.new("4.234")
3.times { results[:big_decimal] << Benchmark.realtime { operations.times { one * two } } }

if helper.load_or_omit(:money)
  Money.add_rate("USD", "CAD", 1.24515)
  results[:money] = []
  3.times { results[:money] << Benchmark.realtime { operations.times { Money.us_dollar(50) * 0.29 } } }
end

if helper.load_or_omit(:exchange)
  1.usd.to_cad #make the rate available in memory
  results[:exchange] = []
  3.times { results[:exchange] << Benchmark.realtime { operations.times { 50.usd * 0.29 } } }
end

puts "#{operations} operations\n\n"
puts "Normal Float Operation takes \t#{helper.median(results[:normal_float])}s\n"
puts "Big Decimal Operation takes \t#{helper.median(results[:big_decimal])}s\n"
puts "Money gem Operation takes \t#{helper.median(results[:money])}s\n" if results[:money]
puts "Exchange gem Operation takes \t#{helper.median(results[:exchange])}s\n" if results[:exchange]