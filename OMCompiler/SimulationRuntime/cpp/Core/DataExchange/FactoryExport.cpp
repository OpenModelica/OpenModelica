/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

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
