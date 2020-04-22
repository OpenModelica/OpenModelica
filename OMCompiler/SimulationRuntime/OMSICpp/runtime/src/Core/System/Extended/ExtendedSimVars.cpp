/** @addtogroup coreSystem
*
*  @{
*/
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

#include <Core/System/FactoryExport.h>
#include <Core/System/ExtendedSimVars.h>
#include <boost/lambda/bind.hpp>
#include <boost/lambda/lambda.hpp>

/**
* Constructor for ExtendedSimVars, stores all model variable in continuous block of memory
* @param dim_real  number of all real variables (real algebraic vars,discrete algebraic vars, state vars, der state vars)
* @param dim_int   number of all integer variables integer algebraic vars
* @param dim_bool  number of all bool variables (boolean algebraic vars)
* @param dim_string  number of all string variables (string algebraic vars)
* @param dim_pre_vars number of all pre variables (real algebraic vars,discrete algebraic vars, boolean algebraic vars, integer algebraic vars, state vars, der state vars)
* @param dim_state_vars number of all state variables
* @param state_index start index of state vector in real_vars list
*/
ExtendedSimVars::ExtendedSimVars(size_t dim_real, size_t dim_int, size_t dim_bool, size_t dim_string, size_t dim_pre_vars,
                 size_t dim_state_vars, size_t state_index)
    :SimVars( dim_real,  dim_int,  dim_bool,  dim_string,  dim_pre_vars, dim_state_vars, state_index)
    
{
  _use_omsu = false;
}

ExtendedSimVars::ExtendedSimVars(omsi_t* omsu)
    :SimVars()
{
    _use_omsu = true;
    create(omsu);
}

ExtendedSimVars::ExtendedSimVars(ExtendedSimVars& instance)
    :SimVars(instance)
{
  
}



void ExtendedSimVars::create(omsi_t* omsu)
{
    _dim_real = omsu->sim_data->model_vars_and_params->n_reals;
    _dim_int = omsu->sim_data->model_vars_and_params->n_ints;
    _dim_bool = omsu->sim_data->model_vars_and_params->n_bools;
    _dim_z = omsu->model_data->n_states;
    _dim_string = omsu->sim_data->model_vars_and_params->n_strings;
    _dim_pre_vars = _dim_real + _dim_int + _dim_bool;
    _z_i = 0;

    //Todo:
    //if (dim_string > 0) {
    //    _string_vars = new string[dim_string];
    //}
    //else {
    //    _string_vars = NULL;
    //}
    
    if (_dim_bool > 0)
    {
        if (!omsu->sim_data->model_vars_and_params->bools)
            throw ModelicaSimulationError(MODEL_EQ_SYSTEM, "omsu integer model variables are not allocated");
        if (!omsu->sim_data->pre_vars->bools)
            throw ModelicaSimulationError(MODEL_EQ_SYSTEM, "omsu integer model variables are not allocated");
        _omsi_bool_vars = omsu->sim_data->model_vars_and_params->bools;
        _pre_omsi_bool_vars = omsu->sim_data->pre_vars->bools;
    }
    else
    {
        _omsi_bool_vars = NULL;
        _pre_omsi_bool_vars = NULL;
    }
    if (_dim_int > 0)
    {
        if (!omsu->sim_data->model_vars_and_params->ints)
            throw ModelicaSimulationError(MODEL_EQ_SYSTEM, "omsu integer model variables are not allocated");
        if (!omsu->sim_data->pre_vars->ints)
            throw ModelicaSimulationError(MODEL_EQ_SYSTEM, "omsu integer model variables are not allocated");
        _int_vars = omsu->sim_data->model_vars_and_params->ints;
        _pre_int_vars = omsu->sim_data->pre_vars->ints;
    }
    else
    {
        _int_vars = NULL;
        _pre_int_vars = NULL;
    }
    if (_dim_real > 0)
    {
        if (!omsu->sim_data->model_vars_and_params->reals)
            throw ModelicaSimulationError(MODEL_EQ_SYSTEM, "omsu real model variables are not allocated");
        if (!omsu->sim_data->pre_vars->reals)
            throw ModelicaSimulationError(MODEL_EQ_SYSTEM, "omsu real model variables are not allocated");
        _real_vars = omsu->sim_data->model_vars_and_params->reals;
        _pre_real_vars = omsu->sim_data->pre_vars->reals;
    }

    //ToDo:
    //_dim_string = dim_string;
    //_dim_pre_vars = omsu->sim_data->;

    //_dim_z = dim_state_vars;
    //_z_i = 0;

}


ExtendedSimVars::~ExtendedSimVars()
{
}


/** @} */ // end of coreSystem
