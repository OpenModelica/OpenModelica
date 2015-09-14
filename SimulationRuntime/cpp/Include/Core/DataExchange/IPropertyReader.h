#pragma once



//#include "FactoryExport.h"
//#include <Core/Utils/extension/logger.hpp>

class IPropertyReader
{
  public:
    IPropertyReader() {}
    virtual ~IPropertyReader() {}

    virtual void readInitialValues(IContinuous& system, boost::shared_ptr<ISimVars> sim_vars) = 0;
};
