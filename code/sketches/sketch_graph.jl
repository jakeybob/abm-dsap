cd(@__DIR__)
import Pkg
Pkg.activate(".")

using Graphs, GraphPlot
g = path_graph(6)
nv(g)
ne(g)
gplot(g, nodelabel=1:nv(g))
add_edge!(g, 1, 6);

gplot(g, nodelabel=1:nv(g))
adjacency_matrix(g)
incidence_matrix(g)
laplacian_matrix(g)
add_vertex!(g)
gplot(g, nodelabel=1:nv(g))
add_edge!(g, 4, 7)
gplot(g, nodelabel=1:nv(g))

g2 = complete_digraph(6)
gplot(g2, nodelabel=1:nv(g2))
adjacency_matrix(g2)

# metal plate
□ = Graph(4)
add_edge!(□, 1, 2)
add_edge!(□, 1, 3)
add_edge!(□, 2, 4)
add_edge!(□, 3, 4)
gplot(□)

# airplane skeleton
skeleton = Graph(11)
add_edge!(skeleton, 1, 2)
add_edge!(skeleton, 2, 3)
add_edge!(skeleton, 3, 4)
add_edge!(skeleton, 4, 5)
add_edge!(skeleton, 3, 6)
add_edge!(skeleton, 3, 7)
add_edge!(skeleton, 3, 8)
add_edge!(skeleton, 3, 9)
add_edge!(skeleton, 9, 10)
add_edge!(skeleton, 9, 11)
gplot(skeleton)

gplot(cartesian_product(□, skeleton))
gplot(cartesian_product(□, □))


⎔ = Graph(6)
add_edge!(⎔, 1, 2)
add_edge!(⎔, 2, 3)
add_edge!(⎔, 3, 4)
add_edge!(⎔, 4, 5)
add_edge!(⎔, 5, 6)
add_edge!(⎔, 6, 1)
gplot(⎔)

gplot(cartesian_product(Graph(1), ⎔))


⎔ = Graph(7)
add_edge!(⎔, 1, 2)
add_edge!(⎔, 2, 3)
add_edge!(⎔, 3, 4)
add_edge!(⎔, 4, 5)
add_edge!(⎔, 5, 6)
add_edge!(⎔, 6, 1)
add_edge!(⎔, 7, 1)
add_edge!(⎔, 7, 2)
add_edge!(⎔, 7, 3)
add_edge!(⎔, 7, 4)
add_edge!(⎔, 7, 5)
add_edge!(⎔, 7, 6)
gplot(⎔)

function centred_cell(num_vertices)
    @assert num_vertices > 2 "need at least 3 outer vertices"
    cell = Graph(num_vertices + 1)
    # build a "ring" of num_vertices nodes with
    # one other node connected to each
    for vertex in 1:num_vertices
        add_edge!(cell, num_vertices + 1, vertex)
        if vertex != num_vertices
            add_edge!(cell, vertex, vertex + 1) 
        else
            add_edge!(cell, num_vertices, 1) 
        end
    end
    return cell
end

a = centred_cell(19)
a
gplot(a)
adjacency_matrix(a)

line = Graph(2)
add_edge!(line, 1, 2)
gplot(cartesian_product(line, a))