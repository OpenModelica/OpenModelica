#pragma once

#include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>
#include <boost/shared_ptr.hpp>
#include <Core/System/ISimVars.h>

//#include "FactoryExport.h"
//#include <Core/Utils/extension/logger.hpp>

class IPropertyReader
{
  public:
    IPropertyReader() {}
    virtual ~IPropertyReader() {}

    virtual void readInitialValues(IContinuous& system, boost::shared_ptr<ISimVars> sim_vars) = 0;
};
