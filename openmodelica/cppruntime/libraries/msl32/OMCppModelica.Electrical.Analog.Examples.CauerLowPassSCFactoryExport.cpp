/* #include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCExtension.h" */

#if defined(__TRICORE__) || defined(__vxworks)
#include <Core/System/FactoryExport.h>
#include <Core/DataExchange/SimData.h>
#include <Core/System/SimVars.h>
extern "C" IMixedSystem* createModelicaSystem(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> algLoopSolverFactory, boost::shared_ptr<ISimData> simData, boost::shared_ptr<ISimVars> simVars)
{
    return new CauerLowPassSCExtension(globalSettings, algLoopSolverFactory, simData, simVars);
}

extern "C" ISimVars* createSimVars(size_t dim_real, size_t dim_int, size_t dim_bool, size_t dim_pre_vars, size_t dim_z, size_t z_i)
{
    return new SimVars(dim_real, dim_int, dim_bool, dim_pre_vars, dim_z, z_i);
}

extern "C" ISimData* createSimData()
{
    return new SimData();
}

#elif defined (RUNTIME_STATIC_LINKING)

  #include <Core/DataExchange/SimData.h>
  #include <Core/System/SimVars.h>
  #include <SimCoreFactory/OMCFactory/StaticOMCFactory.h>
  #include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCExtension.h"
  
  boost::shared_ptr<ISimData> createSimData()
  {
      boost::shared_ptr<ISimData> data( new SimData() );
      return data;
  }
  
  boost::shared_ptr<ISimData> createSimVars(size_t dim_real, size_t dim_int, size_t dim_bool, size_t dim_pre_vars, size_t dim_z, size_t z_i)
  {
      boost::shared_ptr<ISimVars> var( new SimVars(dim_real, dim_int, dim_bool, dim_pre_vars, dim_z, z_i) );
      return var;
  }
  
  boost::shared_ptr<IMixedSystem> createModelicaSystem(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> algLoopSolverFactory, boost::shared_ptr<ISimData> simData)
  {
      boost::shared_ptr<IMixedSystem> system( new CauerLowPassSCExtension(globalSettings, algLoopSolverFactory, simData) );
      return system;
  }
  
#else

BOOST_EXTENSION_TYPE_MAP_FUNCTION
{
  typedef boost::extensions::factory<IMixedSystem,IGlobalSettings*, boost::shared_ptr<IAlgLoopSolverFactory>, boost::shared_ptr<ISimData>, boost::shared_ptr<ISimVars> > system_factory;
  types.get<std::map<std::string, system_factory> >()["CauerLowPassSC"]
    .system_factory::set<CauerLowPassSCExtension>();
}
#endif