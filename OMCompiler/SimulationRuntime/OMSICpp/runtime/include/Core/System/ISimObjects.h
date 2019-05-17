#pragma once
/** @addtogroup coreSimcontroller
 *
 *  @{
 */
//OpenModelcia Simulation Interface Header
#include <omsi.h>

/**
 *
 */
class ISimObjects
{

public:

  virtual ~ISimObjects() {};
  virtual weak_ptr<ISimData> LoadSimData(string modelKey) = 0;
  /**
  Creates  SimVars object, stores all model variable in continuous block of memory
     @param  model name
     @param dim_real  number of all real variables (real algebraic vars,discrete algebraic vars, state vars, der state vars)
     @param dim_int   number of all integer variables integer algebraic vars
     @param dim_bool  number of all bool variables (boolean algebraic vars)
     @param dim_pre_vars number of all pre variables (real algebraic vars,discrete algebraic vars, boolean algebraic vars, integer algebraic vars, state vars, der state vars)
     @param dim_z number of all state variables
     @param z_i start index of state vector in real_vars list
     */
  virtual weak_ptr<ISimVars> LoadSimVars(string modelKey,size_t dim_real,size_t dim_int,size_t dim_bool,size_t dim_string,size_t dim_pre_vars,size_t dim_z,size_t z_i) = 0;
  virtual weak_ptr<ISimVars> LoadSimVars(string modelKey, omsi_t* omsu) = 0;
  virtual weak_ptr<IHistory> LoadWriter(size_t) = 0;

  virtual shared_ptr<ISimData> getSimData(string modelname) = 0;
  virtual shared_ptr<ISimVars> getSimVars(string modelname) = 0;
  virtual void eraseSimData(string modelname) = 0;
  virtual void eraseSimVars(string modelname) = 0;

  virtual ISimObjects* clone() = 0;

  virtual shared_ptr<IAlgLoopSolverFactory> getAlgLoopSolverFactory() = 0;
};
/** @} */ // end of coreSimcontroller
