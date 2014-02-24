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



#include "om_pm_model.hpp"


namespace openmodelica {
namespace parmodelica {


OMModel::OMModel() :
    INI_scheduler(INI_system),
    DAE_scheduler(DAE_system),
    ODE_scheduler(ODE_system)
{
    intialized = false;
}



void OMModel::initialize() {

    if(intialized)
        return;

    std::replace(model_name.begin(), model_name.end(), '_', '.');
    std::string xml_file = model_name + "_info.xml";
    std::cout << "Loading " << xml_file << std::endl;

    INI_system.load_from_xml(xml_file, "initial-equations");
    INI_system.construct_graph();
    INI_scheduler.schedule(4);
    std::cout << "INI_system cost = " << INI_system.total_cost << std::endl;
    std::cout << "INI_scheduler cost = " << INI_scheduler.total_parallel_cost << std::endl;
    std::cout << "Peak speedup = " << INI_system.total_cost/INI_scheduler.total_parallel_cost << std::endl;

    DAE_system.load_from_xml(xml_file, "dae-equations");
    DAE_system.construct_graph();
    DAE_scheduler.schedule(4);
    std::cout << "DAE_system cost = " << DAE_system.total_cost << std::endl;
    std::cout << "DAE_scheduler cost = " << DAE_scheduler.total_parallel_cost << std::endl;
    std::cout << "Peak speedup = " << DAE_system.total_cost/DAE_scheduler.total_parallel_cost << std::endl;

    ODE_system.load_from_xml(xml_file, "ode-equations");
    ODE_system.construct_graph();
    ODE_scheduler.schedule(4);
    std::cout << "ODE_system cost = " << ODE_system.total_cost << std::endl;
    std::cout << "ODE_scheduler cost = " << ODE_scheduler.total_parallel_cost << std::endl;
    std::cout << "Peak speedup = " << ODE_system.total_cost/ODE_scheduler.total_parallel_cost << std::endl;
    std::cout << "-------------------------------------------------------------" << std::endl;

    intialized = true;

}


void OMModel::system_execute(LevelScheduler<Equation>& scheduler, functionXXX_system* functionxxx_systems) {

    LevelScheduler<Equation>::GraphType& system_graph = scheduler.task_system.graph;
    LevelScheduler<Equation>::ProcessorQueuesAllLevelsType::const_iterator pq_level_iter;
    pq_level_iter = scheduler.processor_queue_levels.begin() + 1;

    /*! Do profiling and reschedule*/
    if(!scheduler.profiled) {
    
        std::cout << "system cost before = " << scheduler.task_system.total_cost << std::endl;
        std::cout << "Scheduler cost before = " << scheduler.total_parallel_cost << std::endl;
        std::cout << "Peak speedup before = " << scheduler.task_system.total_cost/scheduler.total_parallel_cost << std::endl;
        
        
        scheduler.task_system.total_cost = 0;
        PMTimer cost_timer;
        double curr_cost;
        for(; pq_level_iter != scheduler.processor_queue_levels.end(); ++pq_level_iter) {
            const LevelScheduler<Equation>::ProcessorQueuesType& pqueues = *pq_level_iter;

            for(unsigned j = 0; j < pqueues.size(); ++j) {
                for(unsigned i = 0; i < pqueues[j].nodes.size(); ++i) {
                    cost_timer.start_timer();
                    functionxxx_systems[system_graph[pqueues[j].nodes[i]].node_id](data);
                    cost_timer.stop_timer();
                    curr_cost = cost_timer.get_elapsed_time() * 10000;
                    cost_timer.reset_timer();
                    
                    system_graph[pqueues[j].nodes[i]].cost = curr_cost;
                    scheduler.task_system.total_cost += curr_cost;
                }
            }

        }

        

        scheduler.re_schedule(4);
        scheduler.profiled = true;
        std::cout << "system cost after = " << scheduler.task_system.total_cost << std::endl;
        std::cout << "Scheduler cost after = " << scheduler.total_parallel_cost << std::endl;
        std::cout << "Peak speedup after = " << scheduler.task_system.total_cost/scheduler.total_parallel_cost << std::endl;
        // scheduler.print_schedule(std::cout);
        std::cout << "-------------------------------------------------------------" << std::endl;
    }

    if(scheduler.profiled) {
        for(; pq_level_iter != scheduler.processor_queue_levels.end(); ++pq_level_iter) {
            const LevelScheduler<Equation>::ProcessorQueuesType& pqueues = *pq_level_iter;

            for(unsigned j = 0; j < pqueues.size(); ++j) {
                for(unsigned i = 0; i < pqueues[j].nodes.size(); ++i) {
                    functionxxx_systems[system_graph[pqueues[j].nodes[i]].node_id](data);
                }
            }

        }
    }

}


void OMModel::system_execute_ini() {
    system_execute(INI_scheduler, ini_system_funcs);
}


void OMModel::system_execute_dae() {
    system_execute(DAE_scheduler, dae_system_funcs);
}

void OMModel::system_execute_ode() {
    system_execute(ODE_scheduler, ode_system_funcs);
}





} // openmodelica
} // parmodelica
