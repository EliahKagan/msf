# msf - Finds and visualizes a minimum spanning forest.

require "bit_array"

# Read-only view into a collection, supporting some array-like operations.
class ReadOnlyView(C)
  protected getter collection

  def initialize(@collection : C)
  end

  def same_underlying?(other)
    @collection.same?(other.collection)
  end

  def size
    @collection.size
  end

  def [](index)
    @collection[index]
  end
end

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

# A heap+map data structure for implementing Prim's and Dijkstra's algorithms.
class PrimHeap(K, V)
  struct Entry(K, V)
    getter key : K
    getter value : V

    def initialize(@key, @value)
    end
  end

  @heap = [] of Entry(K, V)  # index => entry
  @lookup = {} of K => Int32 # key => index

  def initialize(&@comparer : V, V -> Int32)
  end

  def empty?
    @heap.empty?
  end

  def size
    @heap.size
  end

  # If *key* is absent, inserts it with *value*. If *key* is present with a
  # value greater than *value*, decreases its value to *value*.
  def push_or_decrease(key : K, value : V)
    index = @lookup[key]?

    if index.nil?
      index = size
      @heap << Entry(K, V).new(key, value)
      update(index)
    elsif @comparer.call(value, @heap[index].value) < 0
      @heap[index] = Entry(K, V).new(key, value)
    else
      return
    end

    sift_up(index)
  end

  # Extracts the minimum entry.
  def pop
    case size
    when 0
      raise IndexError.new("can't pop from empty heap")
    when 1
      @lookup.clear
      @heap.pop
    else
      entry = @heap[0]
      @lookup.delete(entry.key)
      @heap[0] = @heap.pop # Remove the last entry and place it at the front.
      update(0)
      sift_down(0)
      entry
    end
  end

  private def sift_up(child)
    until child.zero?
      parent = (child - 1) // 2
      break if order_ok?(parent, child)
      swap(parent, child)
      child = parent
    end
  end

  private def sift_down(parent)
    loop do
      child = pick_child(parent)
      break if child.nil? || order_ok?(parent, child)
      swap(parent, child)
      parent = child
    end
  end

  private def pick_child(parent)
    left = parent * 2 + 1
    return nil if left >= size
    right = left + 1
    right == size || order_ok?(left, right) ? left : right
  end

  private def order_ok?(parent, child)
    @comparer.call(parent, child) <= 0
  end

  private def swap(parent, child)
    @heap.swap(parent, child)
    update(parent)
    update(child)
  end

  private def update(index)
    @lookup[@heap[index].key] = index
    nil
  end
end

# An edge in a weighted undirected graph.
struct Edge
  getter u : Int32
  getter v : Int32
  getter weight : Int32

  def initialize(@u, @v, @weight)
  end
end

# A weighted undirected graph to compute and output a minimum spanning forest.
class Graph
  @edges = [] of Edge

  def initialize(order : Int32)
    @order = order
  end

  def add_edge(u, v, weight)
    raise ArgumentError.new("vertex u out of range") unless 0 <= u < @order
    raise ArgumentError.new("vertex v out of range") unless 0 <= v < @order
    @edges << Edge.new(u, v, weight)
  end

  def kruskal_msf(io = STDOUT)
    selection = EdgeSelection.new(@order,
                                  ReadOnlyView.new(@edges),
                                  kruskal_msf_edge_bits)
    selection.name = "MSF (Kruskal)"
    selection
  end

  # Gets an array of bits, where bit i is true iff @edges[i] is in the MSF.
  private def kruskal_msf_edge_bits
    sets = DisjointSets.new(@edges.size)
    keeps = BitArray.new(@edges.size)
    sorted_edge_indices.each do |i|
      keeps[i] = sets.union(@edges[i].u, @edges[i].v)
    end
    keeps
  end

  # Sorts edge indices so the edges can be picked up in ascending order by
  # weight. In case of ties, earlier (i.e. first-given) edges win.
  private def sorted_edge_indices
    (0...@edges.size).to_a.sort! do |i, j|
      by_weight = @edges[i].weight <=> @edges[j].weight
      by_weight.zero? ? i <=> j : by_weight
    end
  end
end

class EdgeSelection
  property name : String? = nil
  property indent = 4
  property keep_color = "red"
  property discard_color = "gray"

  protected getter order
  protected getter edges
  protected getter selection

  def initialize(@order : Int32,
                 @edges : ReadOnlyView(Array(Edge)),
                 @selection : BitArray)
  end

  def same_selection?(other : EdgeSelection)
    unless @order == other.order && @edges.same_underlying?(other.edges)
      raise ArgumentError.new("can't compare selections on different graphs")
    end
    @edges == other.edges
  end

  def draw(io = STDOUT)
    margin = " " * @indent
    io.puts %[graph "#{@name || "(untitled)"}" {]

    # Emit the vertices in ascending order, to be drawn as circle.
    (0...@order).each do |vertex|
      io.puts %(#{margin}#{vertex} [shape="circle"])
    end
    io.puts

    # Emit the edges in the order given, colorized according to selection.
    @selection.each_with_index do |selected, i|
      edgespec = %(#{@edges[i].u} -- #{@edges[i].v})
      colorspec = %(color="#{selected ? keep_color : discard_color}")
      labelspec = %(label="#{@edges[i].weight}")
      io.puts "#{margin}#{edgespec} [#{colorspec} #{labelspec}]"
    end

    io.puts "}"
  end
end

# Read an order and list of weighted edges as a graph.
def read_graph(io)
  # FIXME: Show a proper error message on failure.
  graph = Graph.new(io.gets.as(String).to_i)

  io.each_line.map(&.split.map(&.to_i)).each do |(u, v, weight)|
    graph.add_edge(u, v, weight)
  end

  graph
end

read_graph(ARGF).kruskal_msf.draw
