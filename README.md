<!--
    Copyright (C) 2021 Eliah Kagan <degeneracypressure@gmail.com>

    Permission to use, copy, modify, and/or distribute this software for any
    purpose with or without fee is hereby granted.

    THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
    REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
    AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
    INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
    LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
    OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
    PERFORMANCE OF THIS SOFTWARE.
-->

# msf - minimum spanning forests

`msf` computes [minimum spanning
forests](https://en.wikipedia.org/wiki/Minimum_spanning_tree) of a possibly
unconnected weighted undirected graph using two techniques: [Kruskal&rsquo;s
algorithm](https://en.wikipedia.org/wiki/Kruskal%27s_algorithm), and
[Prim&rsquo;s algorithm](https://en.wikipedia.org/wiki/Prim%27s_algorithm)
repeated for each component.

It outputs [DOT code](https://graphviz.org/doc/info/lang.html) describing the
full graph it was given, with a minimum spanning forest&rsquo;s edges colored
red, and any other edges colored black. You can supply that DOT code as input
to [GraphViz](https://graphviz.org/) utilities, such as `dot`, to render nice
images of the graph. (You can [install
GraphViz](https://graphviz.org/download/) in the traditional manner and run it;
or you can use [GraphViz Online](https://dreampuf.github.io/GraphvizOnline) by
[dreampuf](https://github.com/dreampuf/GraphvizOnline).)

The DOT code `msf` emits actually describes *two* graphs&mdash;one showing the
MSF obtained by Kruskal&rsquo;s algorithm, and the other for the MSF obtained
by Prim&rsquo;s algorithm. These MSFs are often, but not always, the same. But
since they are minimum spanning forests of the same graph, they are guaranteed
to be the same when no two edges in any component of the graph have the same
weight, and they are guaranteed to have the same total weight even if they are
not the same.

## License

Everything in this repository is licensed under
[0BSD](https://spdx.org/licenses/0BSD.html). See [**`LICENSE`**](LICENSE).

## Other Work

`msf` is conceptually related to
[&ldquo;Dijkstra,&rdquo;](https://github.com/EliahKagan/Dijkstra) which is a
much more substantial project.

Both generate DOT code to draw pretty pictures&mdash;though
&ldquo;Dijkstra&rdquo; then actually (by default) invokes `dot` to draw the
pictures, while this does not.

Another connection is that one of the algorithms `msf` uses is [Prim&rsquo;s
algorithm](https://en.wikipedia.org/wiki/Prim%27s_algorithm), which is very
similar to [Dijkstra&rsquo;s
algorithm](https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm). For this
reason, both repositories contain implementations of a [binary
minheap](https://en.wikipedia.org/wiki/Binary_heap) + map data structure,
though &ldquo;Dijkstra&rdquo; contains [implementations of a few alternative
data
structures](https://github.com/EliahKagan/Dijkstra#choose-your-priority-queue-data-structures)
with different performance characteristics, including a [Fibonacci
heap](https://en.wikipedia.org/wiki/Fibonacci_heap), while this does not.

## History

This README itself was written in 2021.

I wrote the main program, [`msf`](#how-to-use), as well as the basic graph
generator, [`randgraph`](#graph-generator), in 2020, for practice while
learning [Crystal](https://crystal-lang.org/). The code here was originally in
the [crystal-sketches](https://github.com/EliahKagan/crystal-sketches)
repository. I made this repository by rebasing just the relevant commits, then
committed removals of the files in crystal-sketches (so they&rsquo;re still in
the history there, but unrelated files from that repository are not in this
repo&rsquo;s history).

I wrote the auxiliary minimum spanning *tree* utility
[`mst-weight-prim`](#minimum-spanning-tree-utility) (a C# program) around the
same time, originally [as a HackerRank
solution](https://github.com/EliahKagan/practice/blob/main/hackerrank/algorithms/graph-theory/primsmstsub/primsmstsub.cs).
The version here is adapted to accept input in the same format, with the same
meaning, as `msf`: the major input-format changes are zero-based indexing, and
an automatic start vertex of 0.

## How to Use

`msf` is a [Crystal](https://crystal-lang.org/) program. Currently it only runs
on [Unix-like](https://en.wikipedia.org/wiki/Unix-like) operating systems.
(Crystal doesn&rsquo;t officially support Windows as of this
writing&mdash;though it, and thus `msf`, works on
[WSL](https://docs.microsoft.com/en-us/windows/wsl/).)

**The main file is `msf.cr`.**

To use `msf`:

1. Install [the Crystal compiler](https://crystal-lang.org/install/) if you
   don&rsquo;t already have it.

2. Having cloned this repository and `cd`ed to the top-level directory of the
   working tree, build the program by running:

   ```bash
   crystal build msf.cr
   ```

   That produces the executable `msf`.

3. Run `msf`, giving it a graph description (see below) as input, either by
   passing it a filename, or via standard input.

**`msf` produces [DOT code](https://graphviz.org/doc/info/lang.html) as output,
but it expects input in a simpler format.** Each graph is assumed to consist of
vertices identified by numbers, running from 0 to one less than the order of
(i.e., number of vertices in) the graph. The input must consist of the order of
the graph on a line by itself, followed by zero or more lines describing edges.
Each line describing an edge must consist of three numbers, separated by
whitespace, where the first and second numbers are the edge&rsquo;s endpoints
and the third is the edge&rsquo;s weight.

For example:

```text
10
2 8 12
4 9 10
2 0 14
2 1 1
```

Weights should be nonnegative, since Prim&rsquo;s algorithm requires that
(though Kruskal&rsquo;s does not). Prim&rsquo;s algorithm can actually be used
with negative edge weights, by first subtracting the least edge weight in the
graph from every edge&rsquo;s weight (i.e., adding its magnitude to every edge
weight), but `msf` does not automatically do that.

## Example Inputs

Four input files describing example graphs are included: `msf.in0`, `msf.in1`,
`msf.in2`, and `msf.in3`. You may want to try those.

For example, to try the program with `msf.in0`, run:

```bash
./msf msf.in0
```

(`./msf < msf.in0` would also work, since `msf` will read standard input when
passed no filename arguments.)

## Graph Generator

A basic random graph generator&mdash;much less sophisticated than [the one in
&ldquo;Dijkstra&rdquo;](https://github.com/EliahKagan/Dijkstra#specify-the-graph)&mdash;is
included. This generates a random weighted undirected graph. The generated
graph may have loops and it may have parallel edges.

`randgraph` is the graph generator. Build it by running:

```bash
crystal build randgraph.cr
```

Then run `randgraph`, passing three numbers as command-line arguments: order
(number of vertices), size (number of edges), and maximum weight. Or run it
with no arguments to be reminded of how to use it.

For example, I think I generated `msf.in0` by running:

```bash
./randgraph 10 4 15 > msf.in0
```

If you like, you can pipe the output of `randgraph` directly to `msf`. For
example:

```bash
./randgraph 15 45 100 | ./msf
```

## Minimum Spanning *Tree* Utility

A separate utility to compute the total weight of a minimum spanning *tree* by
Prim&rsquo;s algorithm is included. I originally was using this to help in
debugging and testing. In a connected graph, a minimum spanning tree is the
same as a minimum spanning forest and its total weight must equal the total
weight of all other minimum spanning trees/forests. But in a forest in which
two or more components contain two or more vertices, the weights needn&rsquo;t
be the same and most often differ.

This utility is `mst-weight-prim`. I&rsquo;ve retained it, since it&rsquo;s a
little bit interesting, and because it&rsquo;s closely related to `msf` in the
sense that they both include implementations of Prim&rsquo;s algorithm, in
different languages.

`mst` and `randgraph` are Crystal programs; in contrast, the MST weight
program, `mst-weight-prim`, is a C# program. One way to use it is:

1. Install `mono` if you don&rsquo;s already have it.

2. Compile `mst-weight-prim` by running:

   ```bash
   mcs mst-weight-prim.csc
   ```

   This produces an executable `mst-weight-prim.exe`.

3. Pass it a graph description, in the same format as `mst` expects. **But
   unlike `mst`, filename arguments are not recognized; only standard input is
   read.** (`mst-weight-prim` has minimal features.) So this works:

   ```bash
   ./mst-weight-prim.exe < msf.in0
   ```

   But it does not work without the `<`.

The code is also compatible with .NET Core (or .NET 5), so you can
alternatively compile it as a .NET Core program using the `dotnet` utility, if
you write a `.csproj` (which `dotnet new` will do).

Note that the weight of a minimum spanning tree from a particular vertex, and
the weight of a minimum spanning forest, will only be the same if the graph
consists of a single component, or all components except the one you start in
are isolated vertices (no edges), or (since we are assuming all edges have
nonnegative weight) all edges outside the component you start in have weight 0.

## See Also

[Tushar Roy](https://www.youtube.com/channel/UCZLJf_R2sWyUtXSKiKlyvAw) has made
good videos on [Kruskal&rsquo;s](https://www.youtube.com/watch?v=fAuF0EuZVCk)
and [Prim&rsquo;s](https://www.youtube.com/watch?v=oP2-8ysT3QQ) algorithms. His
videos include explanations of the data structures&mdash;[disjoint-set
union](https://en.wikipedia.org/wiki/Disjoint-set_data_structure), and [binary
minheap](https://en.wikipedia.org/wiki/Binary_heap) + map,
respectively&mdash;that are most commonly used (and which I used here) to
implement them with acceptable efficiency.
