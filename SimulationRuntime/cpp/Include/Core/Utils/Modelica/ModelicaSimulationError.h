#pragma once

//Enum for error types that can occur
enum SIMULATION_ERROR {
                      SOLVER, //all errors occur in solver (Euler,CVode)
                      ALGLOOP_SOLVER, //all errors occur in non-,lin-solver (Kinsol,Newton,Hybrj)
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


//typedefs for error information
typedef boost::error_info<struct tag_error_code,SIMULATION_ERROR> error_id;
typedef boost::error_info<struct tag_error_message,string> error_message;
//Exception class for all exceptions that can occur
struct ModelicaSimulationError: virtual boost::exception, virtual std::exception
{ 
	virtual ~ModelicaSimulationError() throw() {};
};
