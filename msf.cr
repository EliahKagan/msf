# Finds and visualizes a minimum spanning forest.

# Disjoint-set union data structure.
class DisjointSets
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

# Colors for graph edges, used by the `Graph` class.
class Color
  Gray
  Red
end

# A weighted undirected edge.
struct Edge
  getter vertex1 : Int32
  getter vertex2 : Int32
  getter weight : Int32
  property color : Color
end

# A weighted undireected graph with one bit (a "color") stored with each edge.
class Graph
  @edges = [] of Tuple(Int32, Int32, Color)
  @order = 0
end
