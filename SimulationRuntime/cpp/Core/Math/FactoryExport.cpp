

#if defined(__vxworks)

  

#elif defined(SIMSTER_BUILD)
#include <Core/Modelica.h>
#include <SimCoreFactory/Policies/FactoryConfig.h>

extern "C" void BOOST_EXTENSION_EXPORT_DECL extension_export_math(boost::extensions::factory_map & fm)
{

  
}

 #elif defined(OMC_BUILD)
#include <Core/Modelica.h>
#include <SimCoreFactory/Policies/FactoryConfig.h>

/*OMC factory*/
using boost::extensions::factory;
BOOST_EXTENSION_TYPE_MAP_FUNCTION {



}

#else
    error "operating system not supported"
#endif




