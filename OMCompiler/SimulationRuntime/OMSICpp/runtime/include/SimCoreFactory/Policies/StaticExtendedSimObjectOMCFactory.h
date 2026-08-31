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

#pragma once
/** @addtogroup simcorefactoriesPolicies
 *
 *  @{
 */
#include <omsi.h>
shared_ptr<ISimData> createSimDataFunction();


shared_ptr<ISimVars> createExtendedSimVarsFunction(omsi_t * omsu);



shared_ptr<IHistory> createMatFileWriterFactory(shared_ptr<IGlobalSettings> globalSettings, size_t dim);
shared_ptr<IHistory> createTextFileWriterFactory(shared_ptr<IGlobalSettings> globalSettings, size_t dim);
shared_ptr<IHistory> createBufferReaderWriterFactory(shared_ptr<IGlobalSettings> globalSettings, size_t dim);
shared_ptr<IHistory> createDefaultWriterFactory(shared_ptr<IGlobalSettings> globalSettings, size_t dim);

/*
Policy class to create a OMC-,  Modelica- system or AlgLoopSolver
*/
template <class CreationPolicy>
struct StaticExtendedSimObjectOMCFactory : public ObjectFactory<CreationPolicy>
{
public:
    StaticExtendedSimObjectOMCFactory(PATH library_path, PATH modelicasystem_path, PATH config_path)
        : ObjectFactory<CreationPolicy>(library_path, modelicasystem_path, config_path)
    {
    }

    virtual ~StaticExtendedSimObjectOMCFactory()
    {
    }

    shared_ptr<ISimData> createSimData()
    {
        return createSimDataFunction();
    }

    
   
    shared_ptr<ISimVars> createExtendedSimVars(omsi_t* omsu)
    {
        return createExtendedSimVarsFunction(omsu);
    }
   
    shared_ptr<IAlgLoopSolverFactory> createAlgLoopSolverFactory(shared_ptr<IGlobalSettings> globalSettings)
    {
        return createStaticAlgLoopSolverFactory(globalSettings, ObjectFactory<CreationPolicy>::_library_path,
                                                ObjectFactory<CreationPolicy>::_modelicasystem_path);
    }

    shared_ptr<IHistory> createMatFileWriter(shared_ptr<IGlobalSettings> settings, size_t dim)
    {
        shared_ptr<IHistory> writer = createMatFileWriterFactory(settings, dim);
        return writer;
    }

    shared_ptr<IHistory> createTextFileWriter(shared_ptr<IGlobalSettings> settings, size_t dim)
    {
        shared_ptr<IHistory> writer = createTextFileWriterFactory(settings, dim);
        return writer;
    }

    shared_ptr<IHistory> createBufferReaderWriter(shared_ptr<IGlobalSettings> settings, size_t dim)
    {
        shared_ptr<IHistory> writer = createBufferReaderWriterFactory(settings, dim);
        return writer;
    }

    shared_ptr<IHistory> createDefaultWriter(shared_ptr<IGlobalSettings> settings, size_t dim)
    {
        shared_ptr<IHistory> writer = createDefaultWriterFactory(settings, dim);
        return writer;
    }
};

/** @} */ // end of simcorefactoriesPolicies
