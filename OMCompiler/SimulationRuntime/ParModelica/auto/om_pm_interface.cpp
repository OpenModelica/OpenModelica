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

#include "om_pm_interface.hpp"
#include "om_pm_model.hpp"


extern "C" {

using namespace openmodelica::parmodelica;
typedef Equation::FunctionType FunctionType;

PMTimer seq_ode_timer;


void* PM_Model_create(const char* model_name, DATA* data, threadData_t* threadData) {
    OMModel* pm_om_model = new OMModel(model_name);
    pm_om_model->data = data;
    pm_om_model->threadData = threadData;
    return pm_om_model;
}

void PM_Model_load_ODE_system(void* v_model, FunctionType* ode_system_funcs) {

    OMModel& model = *(static_cast<OMModel*>(v_model));
    model.ode_system_funcs = ode_system_funcs;
    model.load_ODE_system();
}


// void PM_functionInitialEquations(int size, FunctionType* functionInitialEquations_systems) {

    // // pm_om_model.ini_system_funcs = functionInitialEquations_systems;
    // // pm_om_model.INI_scheduler.execute();
    // pm_om_model.INI_scheduler.execution_timer.start_timer();
    // for(int i = 0; i < size; ++i)
        // functionInitialEquations_systems[i](data, threadData);
    // pm_om_model.INI_scheduler.execution_timer.stop_timer();

// }


// void PM_functionDAE(int size, FunctionType* functionDAE_systems) {

    // // pm_om_model.dae_system_funcs = functionDAE_systems;
    // // pm_om_model.DAE_scheduler.execute();

    // pm_om_model.DAE_scheduler.execution_timer.start_timer();
    // for(int i = 0; i < size; ++i)
        // functionDAE_systems[i](data, threadData);
    // pm_om_model.DAE_scheduler.execution_timer.stop_timer();

// }


void PM_evaluate_ODE_system(void* v_model) {

    OMModel& model = *(static_cast<OMModel*>(v_model));
    model.ODE_scheduler.execute();

    // pm_om_model.ODE_scheduler.execution_timer.start_timer();
    // for(int i = 0; i < size; ++i)
        // functionODE_systems[i](data, threadData);
    // pm_om_model.ODE_scheduler.execution_timer.stop_timer();

}

// void PM_functionAlg(int size, DATA* data, threadData_t* threadData, FunctionType* functionAlg_systems) {

    // pm_om_model.ALG_scheduler.execution_timer.start_timer();

    // for(int i = 0; i < size; ++i)
        // functionAlg_systems[i](data, threadData);

    // pm_om_model.ALG_scheduler.execution_timer.start_timer();

// }

void seq_ode_timer_start() {
    seq_ode_timer.start_timer();
}

void seq_ode_timer_stop() {
    seq_ode_timer.stop_timer();
}

void seq_ode_timer_reset() {
    seq_ode_timer.reset_timer();
}

void seq_ode_timer_get_elapsed_time2() {
    // return seq_ode_timer.get_elapsed_time();
    std::cerr << seq_ode_timer.get_elapsed_time();
}

double seq_ode_timer_get_elapsed_time() {
    return seq_ode_timer.get_elapsed_time();
}

void dump_times(void* v_model) {
    OMModel& model = *(static_cast<OMModel*>(v_model));

    // utility::log("") << "Total INI: " << model.INI_scheduler.execution_timer.get_elapsed_time() << std::endl;
    // utility::log("") << "Total DAE: " << model.DAE_scheduler.execution_timer.get_elapsed_time() << std::endl;
    // utility::log("") << "Total ALG: " << model.ALG_scheduler.execution_timer.get_elapsed_time() << std::endl;

    // double total = 0;
    // for(unsigned int i = 0; i < model.ODE_scheduler.parallel_eval_costs.size(); ++i) {
        // double c = model.ODE_scheduler.parallel_eval_costs[i];
        // total += c;
        // utility::log("") << i+1 << ": " << c << " : " << total/(i+1) << std::endl;
    // }

    // utility::log("") << "Total ODE added: " << total << std::endl;
    // std::cout << model.ODE_scheduler.execution_timer.get_elapsed_time() << std::endl;
    // std::cout << model.ODE_scheduler.total_evaluations << " : " << model.ODE_scheduler.total_parallel_cost << std::endl;
#ifdef USE_LEVEL_SCHEDULER
    utility::log("") << "Using level scheduler" << std::endl;
#else
  #ifdef USE_FLOW_SCHEDULER
    utility::log("") << "Using flow scheduler" << std::endl;
  #else
    #error "please specify scheduler. See makefile"
  #endif
#endif
    utility::log("") << "Nr.of threads " << NUM_THREADS << std::endl;
    utility::log("") << "Nr.of ODE evaluations: " << model.ODE_scheduler.total_evaluations << std::endl;
    utility::log("") << "Nr.of profiling ODE Evaluations: " << model.ODE_scheduler.sequential_evaluations << std::endl;
    // utility::log("") << "Total ODE evaluation time : " << model.ODE_scheduler.total_parallel_cost << std::endl;
    utility::log("") << "Total ODE evaluation time : " << model.ODE_scheduler.execution_timer.get_elapsed_time() << std::endl;
    utility::log("") << "Avg. ODE evaluation time : " << model.ODE_scheduler.execution_timer.get_elapsed_time()/model.ODE_scheduler.parallel_evaluations << std::endl;
    utility::log("") << "Total ODE loading time: " << model.load_system_timer.get_elapsed_time() << std::endl;
    utility::log("") << "Total ODE Clustering time: " << model.ODE_scheduler.clustering_timer.get_elapsed_time() << std::endl;
}




} // extern "C"