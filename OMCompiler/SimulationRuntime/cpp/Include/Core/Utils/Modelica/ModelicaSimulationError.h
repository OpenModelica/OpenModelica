#pragma once
/** @addtogroup coreUtils
 *
 *  @{
 */


//Enum for error types that can occur
enum SIMULATION_ERROR {
                      SOLVER, //all errors occur in solver (Euler,CVode)
                      ALGLOOP_SOLVER, //all errors occur in non-,lin-solver (Nox,Kinsol,Newton,Hybrj)
                      MODEL_EQ_SYSTEM, //all errors occur in model system class during simulation
                      ALGLOOP_EQ_SYSTEM,//all errors occur in algloop system class during simulation
                      MODEL_FACTORY, //all errors occur model system factory classes
                      SIMMANAGER,//all errors occur in simulation manager
                      EVENT_HANDLING,//all errors occur during event handling
                      TIME_EVENTS, //all errors occur during handling time events
                      DATASTORAGE , //all errors occur during write data (TextfileWriter,MatfileWriter,BufferReaderWriter
                      UTILITY,//all errors occur in utility functions
                      MODEL_ARRAY_FUNCTION,//all errors occur in array functions
                      MATH_FUNCTION //all errors occur in math functions
                      };

/*
Exception class for all simulation errors
*/
class ModelicaSimulationError : public runtime_error
{
  public:
    /**
     * Create a new modelica error object with the given arguments.
     * @param error_id The identifier related to the sender of the error. \see SIMULATION_ERROR for detail.
     * @param error_info Error message that should be shown.
     * @param description More detailed description of the occurred error e.g. the error-message of the inner exception
     * @param suppress Set to true if the error should not appear on std::err and std::out.
     */
    ModelicaSimulationError(SIMULATION_ERROR error_id, const string& error_info, string description = "", bool suppress = false)
    : runtime_error(error_info + (description.size() > 0 ? "\n" + description : ""))
    , _error_id(error_id)
    , _suppress(suppress)
    {
    }

    SIMULATION_ERROR getErrorID()
    {
      return _error_id;
    }

    bool isSuppressed()
    {
      return _suppress;
    }

  private:
    SIMULATION_ERROR _error_id;
    bool _suppress;
};

 //Helper functions to convert the error id to a readable format
#if defined (__vxworks) || defined (__TRICORE__)
/* adrpo: undefine BOOST_EXTENSION_EXPORT_DECL for these targets */
#define BOOST_EXTENSION_EXPORT_DECL
#endif
//Helper functions to convert the error id to a readable format
BOOST_EXTENSION_EXPORT_DECL string error_id_string(SIMULATION_ERROR id);
//Helper functions to extend an error information for new additional string and time stamp
BOOST_EXTENSION_EXPORT_DECL string add_error_info(string new_info,string info,SIMULATION_ERROR id,double& time);
//Helper functions to extend an error information for new additional string
BOOST_EXTENSION_EXPORT_DECL string add_error_info(string new_info,string info,SIMULATION_ERROR id);
/** @} */ // end of coreUtils
