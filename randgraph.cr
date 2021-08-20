# Copyright (C) 2020 Eliah Kagan <degeneracypressure@gmail.com>
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.

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
