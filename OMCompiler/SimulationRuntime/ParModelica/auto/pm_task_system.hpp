#pragma once
#ifndef idC32CC0E3_D0E1_479D_85BC0769EFD475C0
#define idC32CC0E3_D0E1_479D_85BC0769EFD475C0

/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*
 Mahder.Gebremedhin@liu.se  2020-10-12
*/

#include <iostream>

#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/graph_utility.hpp>

#include "pm_utility.hpp"

namespace openmodelica { namespace parmodelica {

struct TaskNode {
    TaskNode() : level(0), cost(0){};

    long   task_id;
    int    level;
    double cost;

    virtual bool depends_on(const TaskNode&) const = 0;
};

template <typename TaskTypeT>
class TaskSystem : boost::noncopyable {
    std::string model_name;

  public:
    typedef TaskTypeT                                                                                 TaskType;
    typedef typename boost::adjacency_list<boost::setS, boost::vecS, boost::bidirectionalS, TaskType> Graph;
    typedef typename Graph::vertex_descriptor                    Node; // rename me to NodeType
    typedef typename Graph::vertices_size_type                   vertices_size_type;
    typedef typename boost::graph_traits<Graph>::vertex_iterator vertex_iterator;

    typedef typename Graph::edge_descriptor Edge;

    Graph  graph;
    Node   root_node;
    double total_cost;
    long   node_count;

    TaskSystem() : total_cost(0) {
        root_node = boost::add_vertex(graph);
        graph[root_node].node_id = -1;
        node_count = 0;
    }

    TaskType& add_node() {
        Node node = boost::add_vertex(graph);
        graph[node].node_id = node_count;
        ++node_count;

        return graph[node];
    }

    void construct_graph() {
        Edge edge;

        std::pair<vertex_iterator, vertex_iterator> vp_out = boost::vertices(graph);
        for (unsigned i = 1; i != *vp_out.second; ++i) {
            int neigh_count = 0;
            for (unsigned j = i - 1; j > 0; --j) {
                bool found_dep = graph[i].depends_on(graph[j]);
                if (found_dep) {
                    bool b;
                    boost::tie(edge, b) = boost::add_edge(j, i, graph);
                    if (!b)
                        utility::log("") << "Error adding Edge- " << graph[j].index << " --> " << graph[i].index
                                         << newl;
                    ++neigh_count;
                }
            }

            if (!neigh_count) {
                bool b;
                boost::tie(edge, b) = boost::add_edge(root_node, i, graph);
                if (!b)
                    utility::log("") << "Error adding Edge- " << graph[root_node].index << " --> " << graph[i].index
                                     << newl;
            }
        }
    }

    void load_from_xml(const std::string& file_name, const std::string& eq_to_read);
};

template <typename TasktypeT>
struct Node_cost_comparatorR {
    typedef typename TaskSystem<TasktypeT>::Graph GraphType;
    typedef typename TaskSystem<TasktypeT>::Node  NodeType;

    const GraphType& graph;
    Node_cost_comparatorR(const GraphType& g) : graph(g) {}

    bool operator()(const NodeType& lhs, const NodeType& rhs) {
        double lhs_cost = graph[lhs].cost;
        double rhs_cost = graph[rhs].cost;
        if (lhs_cost == rhs_cost) {
            int lhs_degree = out_degree(lhs, graph);
            int rhs_degree = out_degree(rhs, graph);
            // if(lhs_degree == rhs_degree) {

            // }
            return lhs_degree > rhs_degree;
        }
        return lhs_cost > rhs_cost;
    }
};

}} // namespace openmodelica::parmodelica

#include "pm_cluster_system.hpp"
#include "pm_load_xml.inl"
#include "pm_task_system.inl"

#endif // header
