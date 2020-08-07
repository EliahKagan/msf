# Finds and visualizes a minimum spanning forest.

# Disjoint-set union data structure.
class DisjointSets
  @parents : Array(Int32)
  @ranks : Array(Int8)

  # Performs *count* makeset operations.
  def initialize(count : Int)
    @parents = (0...count).to_a
    @ranks = [0i8] * count
  end

  # Unites the sets containing elem1 and elem2, if they are different.
  # Returns true if they were different sets, and false if they were the same.
  def union(elem1, elem2)
    # Find the ancestors and stop if they are already the same.
    elem1 = find_set(elem1)
    elem2 = find_set(elem2)
    return false if elem1 == elem2

    # Unite by rank.
    if @ranks[elem1] < @ranks[elem2]
      @parents[elem1] = elem2
    else
      @ranks[elem1] += 1 if @ranks[elem1] == @ranks[elem2]
      @parents[elem2] = elem1
    end

    true
  end

  private def find_set(elem)
    # Find the ancestor.
    leader = elem
    while leader != @parents[leader]
      leader = @parents[leader]
    end

    # Compress the path.
    while elem != leader
      parent = @parents[elem]
      @parents[elem] = leader
      elem = parent
    end

    leader
  end
end

# A weighted undirected graph to compute and output a minimum spanning forest.
class Graph
  property name = "MSF"
  property indent = 4
  property keep_color = "red"
  property discard_color = "gray"

  @edges = [] of NamedTuple(u: Int32, v: Int32, weight: Int32)

  def initialize(order : Int32)
    @order = order
  end

  def add_edge(u, v, weight)
    raise ArgumentError.new("vertex u out of range") unless 0 <= u < @order
    raise ArgumentError.new("vertex v out of range") unless 0 <= v < @order
    @edges << {u: u, v: v, weight: weight}
  end

  def draw_msf(io = STDOUT)
    keeps = msf_edge_bits

    margin = " " * @indent
    io.puts %(graph "#{name}" {)

    # Add the vertices in ascending order, to be drawn as circle.
    (0...@order).each { |vertex| io.puts %(#{margin}#{vertex} [shape=circle]) }
    io.puts

    # Add the edges in the order given, colorized according to MSF membership.
    keeps.each_with_index do |keep, i|
      edgespec = %(#{@edges[i][:u]} -- #{@edges[i][:v]})
      colorspec = %([color="#{keep ? keep_color : discard_color}"])
      labelspec = %([label="#{@edges[i][:weight]}"])
      io.puts "#{margin}#{edgespec} #{colorspec} #{labelspec}"
    end

    io.puts "}"
  end

  # Gets an array of bits, where bit i is true iff @edges[i] is in the MSF.
  private def msf_edge_bits
    sets = DisjointSets.new(@edges.size)
    keeps = [false] * @edges.size
    sorted_edge_indices.each do |i|
      keeps[i] = sets.union(@edges[i][:u], @edges[i][:v])
    end
    keeps
  end

  # Sorts edge indices so the edges can be picked up in ascending order by
  # weight. In case of ties, earlier (i.e. first-given) edges win.
  private def sorted_edge_indices
    (0...@edges.size).to_a.sort! do |i, j|
      by_weight = @edges[i][:weight] <=> @edges[j][:weight]
      by_weight.zero? ? i <=> j : by_weight
    end
  end
end

# Convenience class to read an order and list of weighted edges as a graph.
class GraphBuilder
  @io : IO

  def initialize(@io)
  end

  def read_graph
    # FIXME: Show a proper error message on failure.
    graph = Graph.new(@io.gets.as(String).to_i)

    @io.each_line.map(&.split.map(&.to_i)).each do |(u, v, weight)|
      graph.add_edge(u, v, weight)
    end

    graph
  end
end

GraphBuilder.new(ARGF).read_graph.draw_msf
