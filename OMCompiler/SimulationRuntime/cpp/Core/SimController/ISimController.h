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

struct SimSettings
{
  string solver_name;
  string linear_solver_name;
  std::vector<string> nonlinear_solver_names;
  double start_time;
  double end_time;
  double step_size;
  double lower_limit;
  double upper_limit;
  double tolerance;
  string outputfile_name;
  unsigned int timeOut;
  OutputPointType outputPointType;
  LogSettings logSettings;
  bool nonLinearSolverContinueOnError;
  int solverThreads;
  OutputFormat outputFormat;
  EmitResults emitResults;
  string variableFilter;
  string inputPath;
  string outputPath;
};

/**
 *  SimController to start and stop the simulation
 */
class ISimController
{

public:

  virtual ~ISimController() {};
  virtual weak_ptr<IMixedSystem> LoadSystem(string modelLib,string modelKey) = 0;
  virtual weak_ptr<IMixedSystem> LoadModelicaSystem(PATH modelica_path,string modelKey) = 0;
  virtual void Start(SimSettings simsettings, string modelKey)=0;
  virtual shared_ptr<IMixedSystem> getSystem(string modelname) = 0;
  virtual  shared_ptr<ISimObjects> getSimObjects() = 0;
  virtual void StartReduceDAE(SimSettings simsettings,string modelPath, string modelKey, bool loadMSL, bool loadPackage)=0;
  /**
   *    Stops the simulation
   */
  virtual void Stop() = 0;
};
/** @} */ // end of coreSimcontroller
