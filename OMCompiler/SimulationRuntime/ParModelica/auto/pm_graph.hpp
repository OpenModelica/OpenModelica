/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

#ifndef PM_GRAPH_HPP
#define PM_GRAPH_HPP

#include <list>
#include <map>
#include <set>
#include <utility>

namespace openmodelica { namespace parmodelica {

/**
 * Directed graph with a property per vertex, behaving like
 * boost::adjacency_list<setS, listS, bidirectionalS, VertexProperty>:
 * vertices are kept in insertion order, a vertex descriptor stays valid until
 * that vertex is removed, and the neighbours of a vertex are a set ordered by
 * descriptor.
 */
template <typename VertexProperty>
class DiGraph {
    struct Vertex;

  public:
    typedef Vertex*                                    vertex_descriptor;
    typedef typename std::list<Vertex*>::iterator      vertex_iterator;
    typedef typename std::set<Vertex*>::const_iterator adjacency_iterator;
    typedef adjacency_iterator                         inv_adjacency_iterator;

  private:
    struct Vertex {
        VertexProperty         property;
        std::set<Vertex*>      out;
        std::set<Vertex*>      in;
        vertex_iterator        position;
    };

    mutable std::list<Vertex*> vertex_list;

  public:
    DiGraph() {}
    DiGraph(const DiGraph& other) { copy_from(other); }
    DiGraph& operator=(const DiGraph& other) {
        if (this != &other) {
            clear();
            copy_from(other);
        }
        return *this;
    }
    ~DiGraph() { clear(); }

    VertexProperty&       operator[](vertex_descriptor v) { return v->property; }
    const VertexProperty& operator[](vertex_descriptor v) const { return v->property; }

    vertex_descriptor add_vertex() {
        Vertex* v = new Vertex();
        v->position = vertex_list.insert(vertex_list.end(), v);
        return v;
    }

    /** Returns false if the edge was already there. */
    bool add_edge(vertex_descriptor u, vertex_descriptor v) {
        if (!u->out.insert(v).second)
            return false;
        v->in.insert(u);
        return true;
    }

    void remove_edge(vertex_descriptor u, vertex_descriptor v) {
        u->out.erase(v);
        v->in.erase(u);
    }

    void clear_vertex(vertex_descriptor v) {
        for (Vertex* w : v->out)
            w->in.erase(v);
        for (Vertex* w : v->in)
            w->out.erase(v);
        v->out.clear();
        v->in.clear();
    }

    void remove_vertex(vertex_descriptor v) {
        clear_vertex(v);
        vertex_list.erase(v->position);
        delete v;
    }

    std::pair<vertex_iterator, vertex_iterator> vertices() const {
        return std::make_pair(vertex_list.begin(), vertex_list.end());
    }
    std::pair<adjacency_iterator, adjacency_iterator> adjacent_vertices(vertex_descriptor v) const {
        return std::make_pair(v->out.begin(), v->out.end());
    }
    std::pair<inv_adjacency_iterator, inv_adjacency_iterator> inv_adjacent_vertices(vertex_descriptor v) const {
        return std::make_pair(v->in.begin(), v->in.end());
    }
    size_t num_vertices() const { return vertex_list.size(); }
    size_t out_degree(vertex_descriptor v) const { return v->out.size(); }
    size_t in_degree(vertex_descriptor v) const { return v->in.size(); }

  private:
    void clear() {
        for (Vertex* v : vertex_list)
            delete v;
        vertex_list.clear();
    }

    void copy_from(const DiGraph& other) {
        std::map<const Vertex*, Vertex*> copies;
        for (Vertex* v : other.vertex_list) {
            Vertex* c = add_vertex();
            c->property = v->property;
            copies[v] = c;
        }
        for (Vertex* v : other.vertex_list)
            for (Vertex* w : v->out)
                add_edge(copies[v], copies[w]);
    }
};

template <typename P>
typename DiGraph<P>::vertex_descriptor add_vertex(DiGraph<P>& g) {
    return g.add_vertex();
}
template <typename P>
bool add_edge(typename DiGraph<P>::vertex_descriptor u, typename DiGraph<P>::vertex_descriptor v, DiGraph<P>& g) {
    return g.add_edge(u, v);
}
template <typename P>
void remove_edge(typename DiGraph<P>::vertex_descriptor u, typename DiGraph<P>::vertex_descriptor v, DiGraph<P>& g) {
    g.remove_edge(u, v);
}
template <typename P>
void clear_vertex(typename DiGraph<P>::vertex_descriptor v, DiGraph<P>& g) {
    g.clear_vertex(v);
}
template <typename P>
void remove_vertex(typename DiGraph<P>::vertex_descriptor v, DiGraph<P>& g) {
    g.remove_vertex(v);
}
template <typename P>
std::pair<typename DiGraph<P>::vertex_iterator, typename DiGraph<P>::vertex_iterator> vertices(const DiGraph<P>& g) {
    return g.vertices();
}
template <typename P>
std::pair<typename DiGraph<P>::adjacency_iterator, typename DiGraph<P>::adjacency_iterator>
adjacent_vertices(typename DiGraph<P>::vertex_descriptor v, const DiGraph<P>& g) {
    return g.adjacent_vertices(v);
}
template <typename P>
std::pair<typename DiGraph<P>::inv_adjacency_iterator, typename DiGraph<P>::inv_adjacency_iterator>
inv_adjacent_vertices(typename DiGraph<P>::vertex_descriptor v, const DiGraph<P>& g) {
    return g.inv_adjacent_vertices(v);
}
template <typename P>
size_t num_vertices(const DiGraph<P>& g) {
    return g.num_vertices();
}
template <typename P>
size_t out_degree(typename DiGraph<P>::vertex_descriptor v, const DiGraph<P>& g) {
    return g.out_degree(v);
}
template <typename P>
size_t in_degree(typename DiGraph<P>::vertex_descriptor v, const DiGraph<P>& g) {
    return g.in_degree(v);
}

}} // namespace openmodelica::parmodelica

#endif // PM_GRAPH_HPP
