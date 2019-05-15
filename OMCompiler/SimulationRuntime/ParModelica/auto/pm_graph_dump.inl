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


#include <fstream>
#include <functional>
#include <boost/graph/graphml.hpp>


namespace openmodelica {
namespace parmodelica {


template<typename TaskTypeT>
void dump_graphml(TaskSystem<TaskTypeT>& task_system, const std::string& filename) {

    typedef typename TaskSystem<TaskTypeT>::TaskType Tasktype;

    std::string out_filename = filename + ".graphml";
    std::ofstream outfileml(out_filename.c_str());
    boost::dynamic_properties dp;
    dp.property("index", boost::get(&Tasktype::index, task_system.graph));
    dp.property("level", boost::get(&Tasktype::level, task_system.graph));
    dp.property("cost", boost::get(&Tasktype::cost, task_system.graph));
    write_graphml(outfileml, task_system.graph, dp, true);

}




template<typename TaskTypeT>
void dump_graphviz(const TaskSystem<TaskTypeT>& task_system, const std::string& filename) {

    std::string out_filename = filename + ".dot";
    std::ofstream outfileviz(out_filename.c_str());
    // write_graphviz(std::cout, task_system.graph, boost::make_label_writer(boost::get(&TaskTypeT::index, task_system.graph)));
    write_graphviz(outfileviz, task_system.graph, boost::make_label_writer(boost::get(&TaskTypeT::index, task_system.graph)));

}


template<typename T>
void TaskSystem_v2<T>::dump_graphml(const std::string& filename) {

    if(levels_valid == false)
        update_node_levels();


    std::string out_filename = filename + ".graphml";
    std::ofstream outfileml(out_filename.c_str());
    boost::dynamic_properties dp;
    dp.property("index", boost::get(&ClusterType::index_list, sys_graph));
    dp.property("level", boost::get(&ClusterType::level, sys_graph));
    dp.property("cost", boost::get(&ClusterType::cost, sys_graph));



	/*! Now we have listS as vertex container. listS doesn't have VertexIndexMap
	   created by default. So we create one for it here. */
	typedef std::map<ClusterIdType, size_t> ClustIndexMap;
    ClustIndexMap clust_map_index;
    boost::associative_property_map<ClustIndexMap> clust_prop_map_index(clust_map_index);

	size_t node_count = 0;
	BGL_FORALL_VERTICES_T(clust_id, sys_graph, GraphType)
    {
        boost::put(clust_prop_map_index, clust_id, node_count++);
    }

    write_graphml(outfileml, sys_graph, clust_prop_map_index, dp, true);

}



} // openmodelica
} // parmodelica