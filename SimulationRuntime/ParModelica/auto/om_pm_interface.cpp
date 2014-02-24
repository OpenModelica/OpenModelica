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

OMModel pm_om_model;

void PM_Model_init(const char* model_name, DATA* data) {
    pm_om_model.model_name = model_name;
    pm_om_model.data = data;
    
    pm_om_model.initialize();
}

void PM_functionInitialEquations(int size, DATA* data, functionXXX_system* functionInitialEquations_systems) {

    pm_om_model.ini_system_funcs = functionInitialEquations_systems;
    
    pm_om_model.total_ini_time.start_timer();
    pm_om_model.system_execute_ini();
    pm_om_model.total_ini_time.stop_timer();
    
    // for(int i = 0; i < size; ++i)
        // functionInitialEquations_systems[i](data);
}


void PM_functionDAE(int size, DATA* data, functionXXX_system* functionDAE_systems) {
    
    pm_om_model.dae_system_funcs = functionDAE_systems;
    
    pm_om_model.total_dae_time.start_timer();
    pm_om_model.system_execute_dae();
    pm_om_model.total_dae_time.stop_timer();
    
    // for(int i = 0; i < size; ++i)
        // functionDAE_systems[i](data);
        
}


void PM_functionODE(int size, DATA* data, functionXXX_system* functionODE_systems) {
    
    pm_om_model.ode_system_funcs = functionODE_systems;
    
    pm_om_model.total_ode_time.start_timer();
    pm_om_model.system_execute_ode();
    pm_om_model.total_ode_time.stop_timer();
    
    // for(int i = 0; i < size; ++i)
        // functionODE_systems[i](data);
    
}

void PM_functionAlg(int size, DATA* data, functionXXX_system* functionAlg_systems) {
    
    pm_om_model.total_alg_time.start_timer();

    for(int i = 0; i < size; ++i)
        functionAlg_systems[i](data);

    pm_om_model.total_alg_time.stop_timer();

}

void dump_times() {
    std::cout << "Total INI: " << pm_om_model.total_ini_time.get_elapsed_time() << std::endl;
    std::cout << "Total DAE: " << pm_om_model.total_dae_time.get_elapsed_time() << std::endl;
    std::cout << "Total ODE: " << pm_om_model.total_ode_time.get_elapsed_time() << std::endl;
    std::cout << "Total ALG: " << pm_om_model.total_alg_time.get_elapsed_time() << std::endl;
}




} // extern "C"