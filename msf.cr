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

# An immutable key-value pair.
struct KeyValuePair(K, V)
  getter key : K
  getter value : V

  def initialize(@key, @value)
  end
end

# Convenience method for creating key-value pairs.
def make_kv(key : K, value : V) forall K, V
  KeyValuePair(K, V).new(key, value)
end

# A heap+map data structure for implementing Prim's and Dijkstra's algorithms.
class PrimHeap(K, V)
  @heap = [] of KeyValuePair(K, V)  # index => entry
  @lookup = {} of K => Int32 # key => index

  def initialize(&@comparer : V, V -> Int32)
  end

  def empty?
    raise "Bug: empty? inconsistent" if @heap.empty? != @lookup.empty?
    @heap.empty?
  end

  def size
    raise "Bug: size inconsistent" if @heap.size != @lookup.size
    @heap.size
  end

  # If *key* is absent, inserts it with *value*. If *key* is present with a
  # value greater than *value*, decreases its value to *value*.
  def push_or_decrease(key : K, value : V)
    check_strong_ri
    index = @lookup[key]?

    if index.nil?
      index = size
      @heap << make_kv(key, value)
      update(index)
    elsif @comparer.call(value, @heap[index].value) < 0
      @heap[index] = make_kv(key, value)
    else
      return
    end

    sift_up(index)
  end

  # Extracts the minimum entry.
  def pop
    check_strong_ri
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
    check_weak_ri
    original_child = child
    puts "Before sift_up(#{original_child}):"
    pp @heap

    until child.zero?
      parent = (child - 1) // 2
      break if order_ok?(parent, child)
      swap(parent, child)
      child = parent
    end

    puts "After sift_up(#{original_child}):"
    pp @heap
    check_strong_ri
  end

  private def sift_down(parent)
    check_weak_ri
    original_parent = parent
    puts "Before sift_down(#{original_parent}):"
    pp @heap

    loop do
      child = pick_child(parent)
      break if child.nil? || order_ok?(parent, child)
      swap(parent, child)
      parent = child
    end

    puts "After sift_down(#{original_parent}):"
    pp @heap
    check_strong_ri
  end

  private def pick_child(parent)
    left = parent * 2 + 1
    return nil if left >= size
    right = left + 1
    right == size || order_ok?(left, right) ? left : right
  end

  private def order_ok?(parent, child)
    @comparer.call(@heap[parent].value, @heap[child].value) <= 0
  end

  private def swap(parent, child)
    @heap.swap(parent, child)
    update(parent)
    update(child)
    check_weak_ri
  end

  private def update(index)
    @lookup[@heap[index].key] = index
    nil
  end

  private def check_strong_ri
    check_weak_ri
    check_minheap_invariant
  end

  private def check_weak_ri
    raise "Bug: RI: inconsistent sizes" if @heap.size != @lookup.size

    if @heap.map(&.key).size != @heap.size
      raise "Bug: RI: duplicate keys in heap"
    end

    if @heap.map(&.value).size != @heap.size
      # NOTE: This would be okay in some uses, but not as used in this program.
      raise "Bug: RI: duplicate values in heap"
    end

    @heap.map(&.key).each_with_index do |key, index|
      raise "Bug: RI: key-index mismatch" if @lookup[key] != index
    end
  end

  private def check_minheap_invariant
    (0..).each do |parent|
      left = parent * 2 + 1
      break if left >= size

      unless order_ok?(parent, left)
        raise "Bug: RI: left child (#{parent} -> #{left}) violates minheap invariant"
      end

      right = left + 1
      unless right == size || order_ok?(parent, right)
        raise "Bug: RI: right child (#{parent} -> #{right}) violates minheap invariant"
      end
    end
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

  def kruskal_msf
    selection = EdgeSelection.new(@order,
                                  ReadOnlyView.new(@edges),
                                  kruskal_msf_edge_bits)
    selection.name = "MSF (Kruskal)"
    selection
  end

  # Gets an array of bits, where bit i is true iff @edges[i] is in the MSF.
  private def kruskal_msf_edge_bits
    edge_bits = BitArray.new(@edges.size)
    sets = DisjointSets.new(@order)
    sorted_edge_indices.each do |i|
      edge_bits[i] = sets.union(@edges[i].u, @edges[i].v)
    end
    edge_bits
  end

  # Makes an array of all indices into @edges, sorted primarily by weight.
  private def sorted_edge_indices
    (0...@edges.size).to_a.sort! { |i, j| compare_edge_indices(i, j) }
  end

  def prim_msf
    selection = EdgeSelection.new(@order,
                                  ReadOnlyView.new(@edges),
                                  prim_msf_edge_bits)
    selection.name = "MSF (Prim)"
    selection
  end

  private def prim_msf_edge_bits
    edge_bits = BitArray.new(@edges.size)
    heap = PrimHeap(Int32, Int32).new { |i, j| compare_edge_indices(i, j) }
    adj = build_adjacency_list
    vis = BitArray.new(@order) # Vertices visited.
    (0...@order).each do |start|
      set_prim_mst_bits(edge_bits, heap, adj, vis, start) unless vis[start]
    end
    edge_bits
  end

  private def build_adjacency_list
    adj = Array(Array(OutEdge)).new(@order) { [] of OutEdge }

    @edges.each_with_index do |edge, index|
      adj[edge.u] << OutEdge.new(edge.v, index)
      adj[edge.v] << OutEdge.new(edge.u, index)
    end

    adj
  end

  private def set_prim_mst_bits(edge_bits, heap, adj, vis, start)
    raise "Bug: heap should be empty between components" unless heap.empty?
    src_entry = make_kv(start, INVALID_INDEX)
    vis[start] = true

    loop do
      adj[src_entry.key].each do |out_edge|
        next if vis[out_edge.dest]
        heap.push_or_decrease(out_edge.dest, out_edge.index)
      end

      break if heap.empty?

      src_entry = heap.pop
      vis[src_entry.key] = true
      edge_bits[src_entry.value] = true
    end
  end

  # Compares indexes into @edges by edge weight. For edges of the same weight,
  # the index itself is used to break the tie. This way, when the MSF is not
  # unique (as sometimes happens when edge weights are not unique), all MSF
  # algorithms give the same MSF (prefering edges given earlier in the input).
  private def compare_edge_indices(i, j)
    by_weight = @edges[i].weight <=> @edges[j].weight
    by_weight.zero? ? i <=> j : by_weight
  end

  INVALID_INDEX = -1

  private struct OutEdge
    getter dest : Int32
    getter index : Int32

    def initialize(@dest, @index)
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
  protected getter edge_bits

  @weight : Int64? = nil

  def initialize(@order : Int32,
                 @edges : ReadOnlyView(Array(Edge)),
                 @edge_bits : BitArray)
  end

  def same_selection?(other : EdgeSelection)
    unless @order == other.order && @edges.same_underlying?(other.edges)
      raise ArgumentError.new("can't compare selections on different graphs")
    end
    @edge_bits == other.edge_bits
  end

  def weight
    @weight ||= compute_weight
  end

  def compute_weight
    @edge_bits
      .each_with_index
      .select { |(selected, index)| selected }
      .sum(0i64) { |selected, index| @edges[index].weight }
  end

  def draw(io = STDOUT)
    margin = " " * @indent
    label_name = @name || "untitled"
    io.puts %[graph "#{label_name}, total weight #{weight}" {]

    # Emit the vertices in ascending order, to be drawn as circle.
    (0...@order).each do |vertex|
      io.puts %(#{margin}#{vertex} [shape="circle"])
    end
    io.puts

    # Emit the edges in the order given, colorized according to selection.
    @edge_bits.each_with_index do |selected, index|
      edgespec = %(#{@edges[index].u} -- #{@edges[index].v})
      colorspec = %(color="#{selected ? keep_color : discard_color}")
      labelspec = %(label="#{@edges[index].weight}[#{index}]")
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

# Prints a warning message to standard error.
def warn(message)
  STDERR.puts "#{PROGRAM_NAME}: warning: #{message}"
end

graph = read_graph(ARGF)

kruskal = graph.kruskal_msf
kruskal.draw

puts

prim = graph.prim_msf
prim.draw

unless kruskal.same_selection?(prim)
  warn "Kruskal and Prim results have different edges"
end

unless kruskal.weight == prim.weight
  warn "Kruskal and Prim results have different weights!!"
end
