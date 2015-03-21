#pragma once
/*
 * Wrap a Modelica System of the Cpp runtime for FMI 2.0.
 *
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

#include <iostream>
#include <string>
#include <vector>
#include <assert.h>

#include "fmi2Functions.h"
#include "FMU2GlobalSettings.h"

class FMU2Wrapper
{
 public:
  // Creation and destruction of FMU instances and setting logging status
  FMU2Wrapper(fmi2String instanceName, fmi2String GUID,
	      const fmi2CallbackFunctions *functions, fmi2Boolean loggingOn);
  virtual ~FMU2Wrapper();

  virtual fmi2Status setDebugLogging(fmi2Boolean loggingOn);

  // Enter and exit initialization mode, terminate and reset
  virtual fmi2Status setupExperiment(fmi2Boolean toleranceDefined,
				     fmi2Real tolerance,
				     fmi2Real startTime,
				     fmi2Boolean stopTimeDefined,
				     fmi2Real stopTime);
  virtual fmi2Status initialize     ();
  virtual fmi2Status terminate      ();
  virtual fmi2Status reset          ();

  // Getting and setting variable values
  virtual fmi2Status getReal   (const fmi2ValueReference vr[], size_t nvr,
				fmi2Real    value[]);
  virtual fmi2Status getInteger(const fmi2ValueReference vr[], size_t nvr,
				fmi2Integer value[]);
  virtual fmi2Status getBoolean(const fmi2ValueReference vr[], size_t nvr,
				fmi2Boolean value[]);
  virtual fmi2Status getString (const fmi2ValueReference vr[], size_t nvr,
				fmi2String  value[]);

  virtual fmi2Status setReal   (const fmi2ValueReference vr[], size_t nvr,
				const fmi2Real    value[]);
  virtual fmi2Status setInteger(const fmi2ValueReference vr[], size_t nvr,
				const fmi2Integer value[]);
  virtual fmi2Status setBoolean(const fmi2ValueReference vr[], size_t nvr,
				const fmi2Boolean value[]);
  virtual fmi2Status setString (const fmi2ValueReference vr[], size_t nvr,
				const fmi2String  value[]);

  // Enter and exit the different modes for Model Exchange
  virtual fmi2Status newDiscreteStates      (fmi2EventInfo *eventInfo);
  virtual fmi2Status completedIntegratorStep(fmi2Boolean noSetFMUStatePriorToCurrentPoint,
					     fmi2Boolean *enterEventMode,
					     fmi2Boolean *terminateSimulation);

  // Providing independent variables and re-initialization of caching
  virtual fmi2Status setTime                (fmi2Real time);
  virtual fmi2Status setContinuousStates    (const fmi2Real x[], size_t nx);

  // Evaluation of the model equations
  virtual fmi2Status getDerivatives     (fmi2Real derivatives[], size_t nx);
  virtual fmi2Status getEventIndicators (fmi2Real eventIndicators[], size_t ni);
  virtual fmi2Status getContinuousStates(fmi2Real states[], size_t nx);
  virtual fmi2Status getNominalsOfContinuousStates(fmi2Real x_nominal[], size_t nx);

 private:
  FMU2GlobalSettings _global_settings;
  boost::shared_ptr<MODEL_IDENTIFIER> _model;
  std::vector<fmi2Real> _tmp_real_buffer;
  std::vector<fmi2Integer> _tmp_int_buffer;
  std::vector<fmi2Boolean> _tmp_bool_buffer;
  double _need_update;
  void updateModel();

  typedef enum {
    Instantiated       = 1 << 0,
    InitializationMode = 1 << 1,
    EventMode          = 1 << 2,
    ContinuousTimeMode = 1 << 3,
    Terminated         = 1 << 4,
    Error              = 1 << 5,
    Fatal              = 1 << 6
  } ModelState;

  fmi2String _instanceName;
  fmi2String _GUID;
  fmi2CallbackFunctions _functions;
  ModelState _state;
};
