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
#if defined(__vxworks)


#elif defined(SIMSTER_BUILD)

#include <Solver/CppDASSL/CppDASSL.h>


/*Simster factory*/
extern "C" void BOOST_EXTENSION_EXPORT_DECL extension_export_cppdassl(boost::extensions::factory_map & fm)
{
    fm.get<ISolver,int,IMixedSystem*, ISolverSettings*>()[1].set<CppDASSL>();
    //fm.get<ISolverSettings,int, IGlobalSettings* >()[2].set<PeerSettings>();
}

#elif defined(OMC_BUILD)

#include <Solver/CppDASSL/CppDASSL.h>
#include <Solver/CppDASSL/CppDASSLSettings.h>

    /* OMC factory */
    using boost::extensions::factory;

    BOOST_EXTENSION_TYPE_MAP_FUNCTION {
    types.get<std::map<std::string, factory<ISolver,IMixedSystem*, ISolverSettings*> > >()
    ["cppdasslSolver"].set<CppDASSL>();
    types.get<std::map<std::string, factory<ISolverSettings, IGlobalSettings* > > >()
    ["cppdasslSettings"].set<CppDASSLSettings>();
    }

#else
error "operating system not supported"
#endif



