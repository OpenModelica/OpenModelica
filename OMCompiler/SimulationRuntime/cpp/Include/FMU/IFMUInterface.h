#pragma once
/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
/******************************************************************************
 *fmuTemplate.h
 ******************************************************************************/
#include <FMU/fmiModelFunctions.h>

class IFMUInterface
{
  public:
    IFMUInterface(fmiString instanceName, fmiString GUID, fmiCallbackFunctions functions, fmiBoolean loggingOn) :
      instanceName(instanceName), GUID(GUID), functions(functions) {};

    virtual ~IFMUInterface() {};
    virtual fmiStatus setDebugLogging  (fmiBoolean loggingOn) = 0;

/*  independent variables and re-initialization of caching */
    virtual fmiStatus setTime                (fmiReal time) = 0;
    virtual fmiStatus setContinuousStates    (const fmiReal x[], size_t nx) = 0;
    virtual fmiStatus completedIntegratorStep(fmiBoolean& callEventUpdate) = 0;
    virtual fmiStatus setReal                (const fmiValueReference vr[], size_t nvr, const fmiReal    value[]) = 0;
    virtual fmiStatus setInteger             (const fmiValueReference vr[], size_t nvr, const fmiInteger value[]) = 0;
    virtual fmiStatus setBoolean             (const fmiValueReference vr[], size_t nvr, const fmiBoolean value[]) = 0;
    virtual fmiStatus setString              (const fmiValueReference vr[], size_t nvr, const fmiString  value[]) = 0;

/*  of the model equations */
    virtual fmiStatus initialize(fmiBoolean toleranceControlled, fmiReal relativeTolerance, fmiEventInfo& eventInfo) = 0;

    virtual fmiStatus getDerivatives    (fmiReal derivatives[]    , size_t nx) = 0;
    virtual fmiStatus getEventIndicators(fmiReal eventIndicators[], size_t ni) = 0;

    virtual fmiStatus getReal   (const fmiValueReference vr[], size_t nvr, fmiReal    value[]) = 0;
    virtual fmiStatus getInteger(const fmiValueReference vr[], size_t nvr, fmiInteger value[]) = 0;
    virtual fmiStatus getBoolean(const fmiValueReference vr[], size_t nvr, fmiBoolean value[]) = 0;
    virtual fmiStatus getString (const fmiValueReference vr[], size_t nvr, fmiString  value[]) = 0;

    virtual fmiStatus eventUpdate               (fmiBoolean intermediateResults, fmiEventInfo& eventInfo) = 0;
    virtual fmiStatus getContinuousStates       (fmiReal states[], size_t nx) = 0;
    virtual fmiStatus getNominalContinuousStates(fmiReal x_nominal[], size_t nx) = 0;
    virtual fmiStatus getStateValueReferences   (fmiValueReference vrx[], size_t nx) = 0;
    virtual fmiStatus terminate                 () = 0;
    virtual fmiStatus setExternalFunction       (fmiValueReference vr[], size_t nvr, const void* value[]) = 0;

  private:
    typedef enum {
        modelInstantiated = 1<<0,
        modelInitialized  = 1<<1,
        modelTerminated   = 1<<2,
        modelError        = 1<<3
    } ModelState;

    fmiString instanceName;
    fmiString GUID;
    fmiCallbackFunctions functions;
    fmiEventInfo eventInfo;
    ModelState state;
};

