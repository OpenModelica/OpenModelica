/** @addtogroup coreUtils
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

 #include  <Core/Utils/Modelica/ModelicaSimulationError.h>
 string error_id_string(SIMULATION_ERROR id)
 {
     std::map<SIMULATION_ERROR, std::string> error_id_info = MAP_LIST_OF
       SOLVER, "solver" MAP_LIST_SEP
       ALGLOOP_SOLVER, "algloop solver" MAP_LIST_SEP
       MODEL_EQ_SYSTEM, "model equation system" MAP_LIST_SEP
       ALGLOOP_EQ_SYSTEM, "algloop equation system" MAP_LIST_SEP
       MODEL_FACTORY, "model factory" MAP_LIST_SEP
       SIMMANAGER, "simulation manager" MAP_LIST_SEP
       EVENT_HANDLING, "event handling" MAP_LIST_SEP
       TIME_EVENTS, "time event" MAP_LIST_SEP
       DATASTORAGE, "data storage" MAP_LIST_SEP
       UTILITY, "utility" MAP_LIST_SEP
       MODEL_ARRAY_FUNCTION, "array function" MAP_LIST_SEP
       MATH_FUNCTION, "math function" MAP_LIST_END;

     return error_id_info[id];
 }


 string  add_error_info(string new_info,string info,SIMULATION_ERROR id,double& time)
 {
     ostringstream ss;
     ss << new_info << " stopped at time " << time << " with error in " << error_id_string(id) << ": " << std::endl << info;
     return ss.str().c_str();


 }

 string  add_error_info(string new_info,string info,SIMULATION_ERROR id)
 {
     ostringstream ss;
     ss << new_info <<  " with error in " << error_id_string(id) << ": " << std::endl << info;
     return ss.str().c_str();


 }
 /** @} */ // end of coreUtils
