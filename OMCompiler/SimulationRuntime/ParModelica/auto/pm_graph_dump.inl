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

#include <boost/graph/graphml.hpp>
#include <fstream>
#include <functional>

namespace openmodelica { namespace parmodelica {

template <typename TaskTypeT>
void dump_graphml(TaskSystem<TaskTypeT>& task_system, const std::string& filename) {

    typedef typename TaskSystem<TaskTypeT>::TaskType Tasktype;

    std::string               out_filename = filename + ".graphml";
    std::ofstream             outfileml(out_filename.c_str());
    boost::dynamic_properties dp;
    dp.property("index", boost::get(&Tasktype::index, task_system.graph));
    dp.property("level", boost::get(&Tasktype::level, task_system.graph));
    dp.property("cost", boost::get(&Tasktype::cost, task_system.graph));
    write_graphml(outfileml, task_system.graph, dp, true);
}

template <typename TaskTypeT>
void dump_graphviz(const TaskSystem<TaskTypeT>& task_system, const std::string& filename) {

    std::string   out_filename = filename + ".dot";
    std::ofstream outfileviz(out_filename.c_str());
    // write_graphviz(std::cout, task_system.graph, boost::make_label_writer(boost::get(&TaskTypeT::index,
    // task_system.graph)));
    write_graphviz(outfileviz, task_system.graph,
                   boost::make_label_writer(boost::get(&TaskTypeT::index, task_system.graph)));
}

}} // namespace openmodelica::parmodelica
