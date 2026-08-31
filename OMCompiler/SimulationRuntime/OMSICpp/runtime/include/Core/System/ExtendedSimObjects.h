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
/** @addtogroup coreSimcontroller
 *
 *  @{
 */
//omsi header

#include <Core/System/SimObjects.h>
#include <Core/System/IExtendedSimObjects.h>
#include <SimCoreFactory/Policies/FactoryPolicy.h>

class ExtendedSimObjects : public IExtendedSimObjects,  public SimObjects, public ExtendedSimObjectPolicy
{
public:
    ExtendedSimObjects(PATH library_path, PATH modelicasystem_path, shared_ptr<IGlobalSettings> globalSettings);
    ExtendedSimObjects(ExtendedSimObjects& instance);
    virtual ~ExtendedSimObjects();
    virtual weak_ptr<ISimData> LoadSimData(string modelKey);
    virtual weak_ptr<IHistory> LoadWriter(size_t dim);
    virtual shared_ptr<IHistory> getWriter();
    virtual shared_ptr<ISimData> getSimData(string modelname);
    virtual void eraseSimData(string modelname);
    virtual weak_ptr<ISimVars> LoadSimVars(string modelKey, omsi_t* omsu);
    
  
private:
    std::map<string, shared_ptr<ISimData>> _sim_data;
    shared_ptr<IHistory> _write_output;
};

/** @} */ // end of coreSimcontroller
