require "bundler/setup"
Bundler.require(:default)
require "active_record"
require "benchmark"

ActiveRecord::Base.default_timezone = :utc
ActiveRecord::Base.time_zone_aware_attributes = true
ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

ActiveRecord::Migration.create_table :products do |t|
  t.string :name
  t.string :color
  t.integer :store_id
end

class Product < ActiveRecord::Base
  searchkick batch_size: 100

  def search_data
    {
      name: name,
      color: color,
      store_id: store_id
    }
  end
end

Product.import ["name", "color", "store_id"], 20000.times.map { |i| ["Product #{i}", ["red", "blue"].sample, rand(10)] }

puts "Imported"

result = nil
report = nil
stats = nil

# p GetProcessMem.new.mb

time =
  Benchmark.realtime do
    # result = RubyProf.profile do
    # report = MemoryProfiler.report do
    # stats = AllocationStats.trace do
    Product.reindex
    # end
  end

# p GetProcessMem.new.mb

puts time.round(1)
puts Product.searchkick_index.total_docs

if result
  printer = RubyProf::GraphPrinter.new(result)
  printer.print(STDOUT, min_percent: 5)
end

if report
  puts report.pretty_print
end

if stats
  puts result.allocations(alias_paths: true).group_by(:sourcefile, :class).to_text
end
