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
 Mahder.Gebremedhin@liu.se  2014-02-10
*/



#include <iostream>

#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/graph_utility.hpp>
#include <boost/graph/dijkstra_shortest_paths.hpp>

#include "pm_utility.hpp"


namespace openmodelica {
namespace parmodelica {


template <typename TaskTypeT>
class TaskSystem {
    std::string model_name;
    
public:
    typedef TaskTypeT TaskType;
    typedef typename boost::adjacency_list<boost::setS, boost::vecS, boost::bidirectionalS, TaskType> Graph;
    typedef typename Graph::vertex_descriptor Node;
    typedef typename Graph::vertices_size_type vertices_size_type;
    typedef typename boost::graph_traits<Graph>::vertex_iterator vertex_iterator;
    
    typedef typename Graph::edge_descriptor   Edge;
    
    Graph graph;
    Node root_node;
    double total_cost;
    long node_count;    
    
    TaskSystem();
    
    
    TaskType& add_node(long index, const std::set<std::string>& lhs, const std::set<std::string>& rhs);
    TaskType& add_node(long index);
    
    
    void load_from_xml(const std::string& file_name, const std::string& eq_to_read);
    
    void construct_graph();
    
    void dump_graphml(const std::string& file_name);
    void dump_graphviz(const std::string& file_name);
    

};

template<typename TasktypeT>
struct Node_cost_comparatorR {
    typedef typename TaskSystem<TasktypeT>::Graph GraphType;
    typedef typename TaskSystem<TasktypeT>::Node NodeType;
    
    const GraphType& graph;
    Node_cost_comparatorR(const GraphType& g) : graph(g) {}
    
    bool operator() (const NodeType& lhs, const NodeType& rhs) {
        double lhs_cost = graph[lhs].cost;
        double rhs_cost = graph[rhs].cost;
        if(lhs_cost == rhs_cost) {
            int lhs_degree = out_degree(lhs, graph);
            int rhs_degree = out_degree(rhs, graph);
            // if(lhs_degree == rhs_degree) {
                
            // }
            return lhs_degree > rhs_degree; 
        }
        return lhs_cost > rhs_cost;
    }
};
  
  
  
} // openmodelica
} // parmodelica


#include "pm_task_system.inl"
#include "pm_load_xml.inl"



#endif // header