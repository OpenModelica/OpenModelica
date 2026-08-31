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

/******************************************************************************
 *fmuTemplate.h
 ******************************************************************************/
#include <FMU/fmiModelFunctions.h>

class IFMUInterface
{
public:
    IFMUInterface(fmiString instanceName, fmiString GUID, fmiCallbackFunctions functions, fmiBoolean loggingOn) :
        instanceName(instanceName), GUID(GUID), functions(functions)
    {
    };

    virtual ~IFMUInterface()
    {
    };
    virtual fmiStatus setDebugLogging(fmiBoolean loggingOn) = 0;

    /*  independent variables and re-initialization of caching */
    virtual fmiStatus setTime(fmiReal time) = 0;
    virtual fmiStatus setContinuousStates(const fmiReal x[], size_t nx) = 0;
    virtual fmiStatus completedIntegratorStep(fmiBoolean& callEventUpdate) = 0;
    virtual fmiStatus setReal(const fmiValueReference vr[], size_t nvr, const fmiReal value[]) = 0;
    virtual fmiStatus setInteger(const fmiValueReference vr[], size_t nvr, const fmiInteger value[]) = 0;
    virtual fmiStatus setBoolean(const fmiValueReference vr[], size_t nvr, const fmiBoolean value[]) = 0;
    virtual fmiStatus setString(const fmiValueReference vr[], size_t nvr, const fmiString value[]) = 0;

    /*  of the model equations */
    virtual fmiStatus initialize(fmiBoolean toleranceControlled, fmiReal relativeTolerance, fmiEventInfo& eventInfo) =
    0;

    virtual fmiStatus getDerivatives(fmiReal derivatives[], size_t nx) = 0;
    virtual fmiStatus getEventIndicators(fmiReal eventIndicators[], size_t ni) = 0;

    virtual fmiStatus getReal(const fmiValueReference vr[], size_t nvr, fmiReal value[]) = 0;
    virtual fmiStatus getInteger(const fmiValueReference vr[], size_t nvr, fmiInteger value[]) = 0;
    virtual fmiStatus getBoolean(const fmiValueReference vr[], size_t nvr, fmiBoolean value[]) = 0;
    virtual fmiStatus getString(const fmiValueReference vr[], size_t nvr, fmiString value[]) = 0;

    virtual fmiStatus eventUpdate(fmiBoolean intermediateResults, fmiEventInfo& eventInfo) = 0;
    virtual fmiStatus getContinuousStates(fmiReal states[], size_t nx) = 0;
    virtual fmiStatus getNominalContinuousStates(fmiReal x_nominal[], size_t nx) = 0;
    virtual fmiStatus getStateValueReferences(fmiValueReference vrx[], size_t nx) = 0;
    virtual fmiStatus terminate() = 0;
    virtual fmiStatus setExternalFunction(fmiValueReference vr[], size_t nvr, const void* value[]) = 0;

private:
    typedef enum
    {
        modelInstantiated = 1 << 0,
        modelInitialized = 1 << 1,
        modelTerminated = 1 << 2,
        modelError = 1 << 3
    } ModelState;

    fmiString instanceName;
    fmiString GUID;
    fmiCallbackFunctions functions;
    fmiEventInfo eventInfo;
    ModelState state;
};
