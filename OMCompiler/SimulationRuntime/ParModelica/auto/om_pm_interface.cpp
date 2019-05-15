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

OMModel pm_om_model;

void PM_Model_init(const char* model_name, DATA* data, threadData_t* threadData, FunctionType* ode_system) {
    pm_om_model.initialize(model_name, data, threadData, ode_system);
}

void PM_functionInitialEquations(int size, DATA* data, threadData_t* threadData, FunctionType* functionInitialEquations_systems) {

    // pm_om_model.ini_system_funcs = functionInitialEquations_systems;
    // pm_om_model.INI_scheduler.execute();
  pm_om_model.INI_scheduler.execution_timer.start_timer();
    for(int i = 0; i < size; ++i)
        functionInitialEquations_systems[i](data, threadData);
  pm_om_model.INI_scheduler.execution_timer.stop_timer();

}


void PM_functionDAE(int size, DATA* data, threadData_t* threadData, FunctionType* functionDAE_systems) {

    // pm_om_model.dae_system_funcs = functionDAE_systems;
    // pm_om_model.DAE_scheduler.execute();

  pm_om_model.DAE_scheduler.execution_timer.start_timer();
    for(int i = 0; i < size; ++i)
        functionDAE_systems[i](data, threadData);
  pm_om_model.DAE_scheduler.execution_timer.stop_timer();

}


void PM_functionODE(int size, DATA* data, threadData_t* threadData, FunctionType* functionODE_systems) {

    pm_om_model.ODE_scheduler.execute();

  // pm_om_model.ODE_scheduler.execution_timer.start_timer();
    // for(int i = 0; i < size; ++i)
        // functionODE_systems[i](data, threadData);
  // pm_om_model.ODE_scheduler.execution_timer.stop_timer();


  // double step_cost = pm_om_model.ODE_scheduler.execution_timer.get_elapsed_time();
  // std::cout << step_cost << std::endl;
  // pm_om_model.ODE_scheduler.execution_timer.reset_timer();
}

void PM_functionAlg(int size, DATA* data, threadData_t* threadData, FunctionType* functionAlg_systems) {

    pm_om_model.total_alg_time.start_timer();

    for(int i = 0; i < size; ++i)
        functionAlg_systems[i](data, threadData);

    pm_om_model.total_alg_time.stop_timer();

}

void dump_times() {
    utility::log("") << "Total INI: " << pm_om_model.INI_scheduler.execution_timer.get_elapsed_time() << std::endl;
    utility::log("") << "Total DAE: " << pm_om_model.DAE_scheduler.execution_timer.get_elapsed_time() << std::endl;
    utility::log("") << "Total ODE: " << pm_om_model.ODE_scheduler.execution_timer.get_elapsed_time() << std::endl;
    utility::log("") << "Total ODE: " << pm_om_model.ODE_scheduler.clustering_timer.get_elapsed_time() << std::endl;
    utility::log("") << "Total ALG: " << pm_om_model.total_alg_time.get_elapsed_time() << std::endl;
}




} // extern "C"