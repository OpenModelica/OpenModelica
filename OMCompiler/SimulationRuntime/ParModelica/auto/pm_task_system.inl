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

namespace openmodelica { namespace parmodelica {

// template<typename TaskTypeT>
// TaskSystem<TaskTypeT>::TaskSystem() :
// total_cost(0)
// {
// root_node = boost::add_vertex(graph);
// graph[root_node].node_id = -1;
// node_count = 0;
// }

// template<typename TaskTypeT>
// typename TaskSystem<TaskTypeT>::TaskType&
// TaskSystem<TaskTypeT>::add_node() {
// Node node = boost::add_vertex(graph);
// graph[node].node_id = node_count;
// ++node_count;

// return graph[node];
// }

// template<typename TaskTypeT>
// void
// TaskSystem<TaskTypeT>::construct_graph() {

// Edge edge;

// std::pair<vertex_iterator, vertex_iterator> vp_out = boost::vertices(graph);
// for (unsigned i = 1; i != *vp_out.second; ++i) {
// int neigh_count = 0;
// for (unsigned j = i - 1; j > 0; --j) {
// bool found_dep = graph[i].depends_on(graph[j]);
// if(found_dep) {
// bool b;
// boost::tie(edge,b) = boost::add_edge(j,i,graph);
// if(!b)
// utility::log() << "Error adding Edge- " << graph[j].index << " --> " << graph[i].index << newl;
// ++neigh_count;
// }
// }

// if(!neigh_count) {
// bool b;
// boost::tie(edge,b) = boost::add_edge(root_node,i,graph);
// if(!b)
// utility::log() << "Error adding Edge- " << graph[root_node].index << " --> " << graph[i].index << newl;
// }
// }

// }

}} // namespace openmodelica::parmodelica
