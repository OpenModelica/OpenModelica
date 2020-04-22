#pragma once
/** @addtogroup coreSystem
 *
 *  @{
 */

 //omsi header
#include <omsi.h>
#include <Core/System/SimVars.h>

/**
 *  ExtendedSimVars class, implements ISimVars interface
 *  ExtendedSimVars stores all model variable in continuous block of memory
 */

class BOOST_EXTENSION_EXTENDED_SIMVARS_DECL ExtendedSimVars: public SimVars 
{
  public:
    ExtendedSimVars(size_t dim_real, size_t dim_int, size_t dim_bool, size_t dim_string, size_t dim_pre_vars, size_t dim_state_vars, size_t state_index);
    ExtendedSimVars(omsi_t* omsu);
    ExtendedSimVars(ExtendedSimVars& instance);
    ~ExtendedSimVars();
    
  

  private:
  
  
    void create(omsi_t* omsu);
  

  
};

/** @} */ // end of coreSystem
