#pragma once



//#include "FactoryExport.h"
//#include <Core/Utils/extension/logger.hpp>

class IPropertyReader
{
  public:
    IPropertyReader() {}
    virtual ~IPropertyReader() {}


    virtual void readInitialValues(IContinuous& system, shared_ptr<ISimVars> sim_vars) = 0;
    virtual std::string getPropertyFile()= 0;
    virtual void setPropertyFile(std::string file)= 0;
	virtual const output_int_vars_t& getIntOutVars()  = 0;
	virtual const output_real_vars_t& getRealOutVars()= 0;
	virtual const output_bool_vars_t& getBoolOutVars()= 0;
    virtual const output_der_vars_t& getDerOutVars()= 0;
    virtual const output_res_vars_t& getResOutVars()= 0;
};
