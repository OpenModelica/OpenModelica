#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#if defined(__TRICORE__) || defined(__vxworks)

#include <Core/DataExchange/SimData.h>

#elif defined(OMC_BUILD)

 #include <Core/DataExchange/FactoryExport.h>
 #include <Core/DataExchange/SimData.h>
 #include <Core/DataExchange/XmlPropertyReader.h>

  BOOST_EXTENSION_TYPE_MAP_FUNCTION {
    types.get<map<string, boost::extensions::factory<ISimData > > >()
      ["SimData"].set<SimData>();
   /* used late for factory methode createXMLReader
   types.get<std::map<std::string, factory<IPropertyReader,string > > >()
      ["PropertyReader"].set<XmlPropertyReader>();*/
  }

#elif defined(SIMSTER_BUILD)

  #include <Core/ModelicaDefine.h>
 #include <Core/Modelica.h>
  #include <Core/DataExchange/SimData.h>

  /*Simster factory*/
   extern "C" void BOOST_EXTENSION_EXPORT_DECL extension_export_dataExchange(boost::extensions::factory_map & fm)
  {
       fm.get<ISimData,int>()[1].set<SimData>();
  }

#else
  error "operating system not supported"
#endif
