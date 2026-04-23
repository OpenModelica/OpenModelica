/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include "openmodelica.h"
#include "meta/meta_modelica.h"

#define ADD_METARECORD_DEFINITIONS static
#if defined(OMC_BOOTSTRAPPING)
  #include "../boot/tarball-include/OpenModelicaBootstrappingHeader.h"
#else
  #include "../OpenModelicaBootstrappingHeader.h"
#endif


#if !defined(_MSC_VER)
#include "HpcOmBenchmarkExt.cpp"
#else
#include "errorext.h"
#define HPC_OM_VS() c_add_message(NULL, -1, ErrorType_scripting, ErrorLevel_error, "HpcOmBenchmark not supported on Visual Studio.", NULL, 0);MMC_THROW();
#endif

extern "C" {
extern void* HpcOmBenchmarkExt_requiredTimeForOp()
{
#if defined(_MSC_VER)
  HPC_OM_VS();
#else
  return HpcOmBenchmarkExtImpl__requiredTimeForOp();
#endif
}

extern void* HpcOmBenchmarkExt_requiredTimeForComm()
{
#if defined(_MSC_VER)
  HPC_OM_VS();
#else
  return HpcOmBenchmarkExtImpl__requiredTimeForComm();
#endif
}

extern void* HpcOmBenchmarkExt_readCalcTimesFromXml(const char *filename)
{
#if defined(_MSC_VER)
  HPC_OM_VS();
#else
  return HpcOmBenchmarkExtImpl__readCalcTimesFromXml(filename);
#endif
}

extern void* HpcOmBenchmarkExt_readCalcTimesFromJson(const char *filename)
{
#if defined(_MSC_VER)
  HPC_OM_VS();
#else
  return HpcOmBenchmarkExtImpl__readCalcTimesFromJson(filename);
#endif
}
}
