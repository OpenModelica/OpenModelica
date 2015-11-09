#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#if defined(__TRICORE__) || defined(__vxworks)

#include <Core/DataExchange/FactoryExport.h>
#include <Core/DataExchange/SimData.h>
#include <Core/DataExchange/XmlPropertyReader.h>
#include <Core/DataExchange/Writer.h>
#include <Core/DataExchange/Policies/TextfileWriter.h>
#include <Core/DataExchange/Policies/MatfileWriter.h>
#include <Core/DataExchange/Policies/BufferReaderWriter.h>
#include <Core/DataExchange/Policies/DefaultWriter.h>
#include <Core/DataExchange/HistoryImpl.h>
shared_ptr<IHistory> createMatFileWriterFactory(IGlobalSettings& globalSettings,size_t dim)
{
    shared_ptr<IHistory> writer= shared_ptr<IHistory>(new HistoryImpl<MatFileWriter >(globalSettings,dim)  );
    return writer;
}
shared_ptr<IHistory> createTextFileWriterFactory(IGlobalSettings& globalSettings,size_t dim)
{
    shared_ptr<IHistory> writer= shared_ptr<IHistory>(new HistoryImpl<TextFileWriter >(globalSettings,dim)  );
    return writer;
}
shared_ptr<IHistory> createBufferReaderWriterFactory(IGlobalSettings& globalSettings,size_t dim)
{
    shared_ptr<IHistory> writer= shared_ptr<IHistory>(new HistoryImpl<BufferReaderWriter >(globalSettings,dim)  );
    return writer;
}
shared_ptr<IHistory> createDefaultWriterFactory(IGlobalSettings& globalSettings,size_t dim)
{
    shared_ptr<IHistory> writer= shared_ptr<IHistory>(new HistoryImpl<DefaultWriter>(globalSettings,dim)  );
    return writer;
}
#elif defined(OMC_BUILD) && !defined(RUNTIME_STATIC_LINKING)
#include <Core/DataExchange/FactoryExport.h>
#include <Core/DataExchange/SimData.h>
#include <Core/DataExchange/XmlPropertyReader.h>
#include <Core/DataExchange/Writer.h>
#include <Core/DataExchange/Policies/TextfileWriter.h>
#include <Core/DataExchange/Policies/MatfileWriter.h>
#include <Core/DataExchange/Policies/BufferReaderWriter.h>
#include <Core/DataExchange/Policies/DefaultWriter.h>
#include <Core/DataExchange/HistoryImpl.h>
  BOOST_EXTENSION_TYPE_MAP_FUNCTION {
    types.get<map<string, boost::extensions::factory<ISimData > > >()
      ["SimData"].set<SimData>();
   types.get<map<string, boost::extensions::factory<IHistory,IGlobalSettings&,size_t > > >()
      ["MatFileWriter"].set<HistoryImpl<MatFileWriter > >();
  types.get<map<string, boost::extensions::factory<IHistory,IGlobalSettings&,size_t > > >()
      ["TextFileWriter"].set<HistoryImpl<TextFileWriter > >();
  types.get<map<string, boost::extensions::factory<IHistory,IGlobalSettings&,size_t > > >()
      ["BufferReaderWriter"].set<HistoryImpl<BufferReaderWriter > >();
  types.get<map<string, boost::extensions::factory<IHistory,IGlobalSettings&,size_t > > >()
      ["DefaultWriter"].set<HistoryImpl<DefaultWriter > >();
   /* used late for factory methode createXMLReader
   types.get<std::map<std::string, factory<IPropertyReader,string > > >()
      ["PropertyReader"].set<XmlPropertyReader>();*/
  }
#elif defined(OMC_BUILD) && defined(RUNTIME_STATIC_LINKING)
#include <Core/DataExchange/FactoryExport.h>
#include <Core/DataExchange/SimData.h>
#include <Core/DataExchange/XmlPropertyReader.h>
#include <Core/DataExchange/Writer.h>
#include <Core/DataExchange/Policies/TextfileWriter.h>
#include <Core/DataExchange/Policies/MatfileWriter.h>
#include <Core/DataExchange/Policies/BufferReaderWriter.h>
#include <Core/DataExchange/Policies/DefaultWriter.h>
#include <Core/DataExchange/HistoryImpl.h>
shared_ptr<IHistory> createMatFileWriterFactory(IGlobalSettings& globalSettings,size_t dim)
{
    shared_ptr<IHistory> writer= shared_ptr<IHistory>(new HistoryImpl<MatFileWriter >(globalSettings,dim)  );
    return writer;
}
shared_ptr<IHistory> createTextFileWriterFactory(IGlobalSettings& globalSettings,size_t dim)
{
    shared_ptr<IHistory> writer= shared_ptr<IHistory>(new HistoryImpl<TextFileWriter >(globalSettings,dim)  );
    return writer;
}
shared_ptr<IHistory> createBufferReaderWriterFactory(IGlobalSettings& globalSettings,size_t dim)
{
    shared_ptr<IHistory> writer= shared_ptr<IHistory>(new HistoryImpl<BufferReaderWriter >(globalSettings,dim)  );
    return writer;
}
shared_ptr<IHistory> createDefaultWriterFactory(IGlobalSettings& globalSettings,size_t dim)
{
    shared_ptr<IHistory> writer= shared_ptr<IHistory>(new HistoryImpl<DefaultWriter>(globalSettings,dim)  );
    return writer;
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
