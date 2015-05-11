 #include <Core/ModelicaDefine.h>
 #include <Core/Modelica.h>

 #include  <Core/Utils/Modelica/ModelicaSimulationError.h>
 string error_id_string(SIMULATION_ERROR id)
 {
      std::map<SIMULATION_ERROR,std::string> error_id_info= map_list_of(SOLVER,"solver")(ALGLOOP_SOLVER,"algloop solver")(MODEL_EQ_SYSTEM,"model equation system")(ALGLOOP_EQ_SYSTEM,"algloop equation system")
                                                                    ( SOLVER,"csv")(MODEL_FACTORY,"model factory")(SIMMANAGER,"simulation manager")(EVENT_HANDLING,"event handling")
                                                                    (TIME_EVENTS,"time event")( DATASTORAGE,"data storage")(UTILITY,"utility")(MODEL_ARRAY_FUNCTION,"array function")
                                                                    (MATH_FUNCTION,"math function");


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