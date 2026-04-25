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
