// mst-weight-prim - Finds a minimum spanning *tree* (for testing).
//
// Copyright (C) 2020 Eliah Kagan <degeneracypressure@gmail.com>
//
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
// SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
// OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
// CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

using System;
using System.Collections.Generic;

/// <summary>
/// A heap+map structure for implementing Prim's and Dijkstra's algorithms.
/// </summary>
internal sealed class PrimHeap {
    /// <summary>An entry, representing a vertex -> min-cost mapping.</summary>
    internal struct Entry {
        internal Entry(int vertex, int cost)
        {
            Vertex = vertex;
            Cost = cost;
        }

        internal int Vertex { get; }
        internal int Cost { get; }
    }

    /// <summary> Creates a PrimHeap with a set capacity.</summary>
    /// <param name="capacity">The number of vertices supported.</param>
    /// <remarks>Keys must range from 0 to <c>capacity</c> - 1.</remarks>
    internal PrimHeap(int capacity)
    {
        if (capacity < 0) {
            throw new ArgumentOutOfRangeException(
                    paramName: nameof(capacity),
                    message: "a negative capacity makes no sense");
        }

        _heap = new List<Entry>(capacity);

        _map = new int[capacity];
        for (var i = 0; i < _map.Length; ++i) _map[i] = NotFound;
    }

    internal int Count => _heap.Count;

    internal int Capacity => _map.Length;

    internal void InsertOrDecrease(int vertex, int cost)
    {
        if (!(0 <= vertex && vertex < Capacity)) {
            throw new ArgumentOutOfRangeException(
                    paramName: nameof(vertex),
                    message: $"vertex not in range [0, {Capacity})");
        }

        var index = _map[vertex];

        if (index == NotFound) {
            // No entry for this vertex yet exists. It must be inserted.
            index = Count;
            _heap.Add(new Entry(vertex, cost));
        } else if (cost < _heap[index].Cost) {
            // An entry for this vertex exists and is to be decreased.
            _heap[index] = new Entry(vertex, cost);
        } else {
            // An entry for this vertex exists but is not to be decreased.
            return;
        }

        SiftUp(index);
    }

    internal Entry ExtractMin()
    {
        if (Count == 0) {
            throw new InvalidOperationException(
                    "can't extract from empty heap");
        }

        var entry = _heap[0];
        _map[entry.Vertex] = NotFound;

        var last = Count - 1;
        if (last == 0) {
            _heap.Clear();
        } else {
            _heap[0] = _heap[last];
            _heap.RemoveAt(last);
            SiftDown(0);
        }

        return entry;
    }

    private const int NotFound = -1;

    private void SiftUp(int child)
    {
        var entry = _heap[child];

        while (child != 0) {
            var parent = (child - 1) / 2;
            if (_heap[parent].Cost <= entry.Cost) break;

            _heap[child] = _heap[parent];
            UpdateMap(child);
            child = parent;
        }

        _heap[child] = entry;
        UpdateMap(child);
    }

    private void SiftDown(int parent)
    {
        var entry = _heap[parent];

        for (; ; ) {
            var child = PickChild(parent);
            if (child == NotFound || entry.Cost <= _heap[child].Cost) break;

            _heap[parent] = _heap[child];
            UpdateMap(parent);
            parent = child;
        }

        _heap[parent] = entry;
        UpdateMap(parent);
    }

    private int PickChild(int parent)
    {
        var left = parent * 2 + 1;
        if (left >= Count) return NotFound;

        var right = left + 1;

        return right == Count || _heap[left].Cost <= _heap[right].Cost
                ? left
                : right;
    }

    private void UpdateMap(int index) => _map[_heap[index].Vertex] = index;

    private readonly List<Entry> _heap;
    private readonly int[] _map;
}

internal sealed class Graph {
    /// <summary>Creates a graph with a specified number of vertices.</summary>
    /// <param name="order">The vertex count.</param>
    internal Graph(int order)
    {
        if (order < 0) {
            throw new ArgumentOutOfRangeException(
                    paramName: nameof(order),
                    message: "graph can't have negatively many vertices");
        }

        // Create an empty adjacency list.
        _adj = new List<OutEdge>[order];
        for (var i = 0; i < order; ++i) _adj[i] = new List<OutEdge>();
    }

    internal int Order => _adj.Length;

    /// <summary>Adds a weighted edge to this undirected graph.</summary>
    /// <param name="u">The first vertex.</param>
    /// <param name="v">The second vertex.</param>
    /// <param name="weight">The edge weight.</param>
    internal void AddEdge(int u, int v, int weight)
    {
        // This ensures no change is made if an exception is thrown
        // (and also gives an understandable stack trace).
        EnsureExists(nameof(u), u);
        EnsureExists(nameof(v), v);

        // Add entries to both vertices' rows, as the graph is undirected.
        _adj[u].Add(new OutEdge(v, weight));
        _adj[v].Add(new OutEdge(u, weight));
    }

    internal long ComputePrimMstTotalWeight(int start)
    {
        EnsureExists(nameof(start), start);

        long totalCost = 0;
        var processed = new bool[Order];
        var heap = new PrimHeap(Order);

        for (heap.InsertOrDecrease(start, 0); heap.Count != 0; ) {
            var entry = heap.ExtractMin();
            totalCost += entry.Cost;
            processed[entry.Vertex] = true;

            foreach (var dest in _adj[entry.Vertex]) {
                if (!processed[dest.Vertex])
                    heap.InsertOrDecrease(dest.Vertex, dest.Weight);
            }
        }

        return totalCost;
    }

    private struct OutEdge {
        internal OutEdge(int vertex, int weight)
        {
            Vertex = vertex;
            Weight = weight;
        }

        internal int Vertex { get; }
        internal int Weight { get; }
    }

    private void EnsureExists(string vertexParamName, int vertexValue)
    {
        if (!(0 <= vertexValue && vertexValue < Order)) {
            throw new ArgumentOutOfRangeException(
                    paramName: vertexParamName,
                    message: "vertex out of range (not in graph)");
        }
    }

    private readonly List<OutEdge>[] _adj;
}

internal static class Solution {
    private static int ReadValue() => int.Parse(Console.ReadLine());

    /// <summary>Reads a line as a sequence of integers.</summary>
    /// <returns>
    /// The record read, or null on eof/error or if it is whitespace.
    /// </returns>
    /// <remarks>
    /// This is useful for use in a loop to read lines until end-of-file or a
    /// blank line.
    /// </remarks>
    private static int[] ReadRecord()
    {
        var line = Console.ReadLine();
        if (string.IsNullOrWhiteSpace(line)) return null;

        var tokens = line.Split((char[])null,
                                StringSplitOptions.RemoveEmptyEntries);
        return Array.ConvertAll(tokens, int.Parse);
    }

    private static Graph ReadGraph()
    {
        var order = ReadValue();
        var graph = new Graph(order);

        for (int[] record; (record = ReadRecord()) != null; ) {
            var u = record[0];
            var v = record[1];
            var weight = record[2];
            graph.AddEdge(u, v, weight);
        }

        return graph;
    }

    private static void Main()
    {
        var graph = ReadGraph();
        var start = 0; // For now, just try with 0.
        Console.WriteLine(graph.ComputePrimMstTotalWeight(start));
    }
}
