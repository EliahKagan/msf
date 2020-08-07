# Generates a random graph, given an:
# - order (vertex count)
# - size (edge count)
# - maximum edge weight (minimum is 1)
# The graph may contains loops and parallel edges.

if ARGV.empty?
  puts "Usage:  #{PROGRAM_NAME} ORDER SIZE MAX_WEIGHT"
  exit
end

parameters = ARGV.map &.to_i
order, size, max_weight = parameters

puts order

size.times do
  puts "#{rand(0...order)} #{rand(0...order)} #{rand(1..max_weight)}"
end
