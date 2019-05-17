#pragma once

//OpenModelica Simulation Interface
#include <omsi.h>

class IOMSI
{
public:
	virtual omsi_status initialize_omsi_evaluate_functions(omsi_function_t* omsi_function) = 0;
	virtual omsi_status omsi_evaluateAll(omsi_function_t* simulation, const omsi_values* model_vars_and_params, void* data) = 0;
};

class IOMSIInitialize
{
public:
	virtual omsi_status initialize_omsi_initialize_functions(omsi_function_t* omsi_function) = 0;
	virtual omsi_status omsi_initializeAll(omsi_function_t* simulation, const omsi_values* model_vars_and_params, void* data) = 0;
};



class OMSICallBackWrapper {
public:
	static omsi_status evaluate(struct omsi_function_t*    this_function,
		const omsi_values*         read_only_vars_and_params,
		void*                      data)
	{

		return _omsu_system->omsi_evaluateAll(this_function, read_only_vars_and_params, data);
	};
	static omsi_status initialize(struct omsi_function_t*    this_function,
		const omsi_values*         read_only_vars_and_params,
		void*                      data)
	{
		return _omsu_initialize->omsi_initializeAll(this_function, read_only_vars_and_params,data);
	};
	static omsi_status setUpInitializeFunction(omsi_function_t* omsi_function)
	{
		return _omsu_initialize->initialize_omsi_initialize_functions(omsi_function);
	};
	static omsi_status setUpEvaluateFunction(omsi_function_t* omsi_function)
	{
		return _omsu_system->initialize_omsi_evaluate_functions(omsi_function);
	};

	static void setOMSISystem(IOMSI& obj)
	{
		_omsu_system = &obj;
	}
	static void setOMSIInitialize(IOMSIInitialize& obj)
	{
		_omsu_initialize = &obj;
	}
private:
	static IOMSI* _omsu_system;
	static IOMSIInitialize* _omsu_initialize;
};
