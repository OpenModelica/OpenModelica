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

encapsulated package CevalScriptBackend

import Absyn;
import DAE;
import FCore;
import GlobalScript;
import SimCode;
import Values;

function runFrontEnd
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path className;
  input Boolean relaxedFrontEnd "Do not check for illegal simulation models, so we allow instantation of packages, etc";
  input Boolean dumpFlat = false;
  output FCore.Cache cache;
  output FCore.Graph env;
  output Option<DAE.DAElist> dae;
  output String flatString;
algorithm
  assert(false, getInstanceName());
end runFrontEnd;

public function translateModel
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path className "path for the model";
  input String inFileNamePrefix;
  input Boolean runBackend "if true, run the backend as well. This will run SimCode and Codegen as well.";
  input Boolean runSilent "if true, flat modelica code will not be dumped to out stream";
  input Option<SimCode.SimulationSettings> inSimSettingsOpt;
  output Boolean success;
  output FCore.Cache outCache;
  output list<String> outLibs;
  output String outFileDir;
  output list<tuple<String,Values.Value>> resultValues;
algorithm
  assert(false, getInstanceName());
end translateModel;

function getSimulationResultType
  output DAE.Type t;
algorithm
  assert(false, getInstanceName());
end getSimulationResultType;

function getDrModelicaSimulationResultType = getSimulationResultType;

function buildSimulationOptionsFromModelExperimentAnnotation
  input Absyn.Path inModelPath;
  input String inFileNamePrefix;
  input Option<GlobalScript.SimulationOptions> defaultOption;
  output GlobalScript.SimulationOptions outSimOpt;
algorithm
  assert(false, getInstanceName());
end buildSimulationOptionsFromModelExperimentAnnotation;

function getSimulationOption
  input GlobalScript.SimulationOptions inSimOpt;
  input String optionName;
  output DAE.Exp outOptionValue;
algorithm
  assert(false, getInstanceName());
end getSimulationOption;

function cevalInteractiveFunctions3
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input String inFunctionName;
  input list<Values.Value> inVals;
  input Absyn.Msg msg;
  output FCore.Cache outCache = inCache;
  output Values.Value outValue = Values.INTEGER(0);
algorithm
  fail() "Do not print errors here; we expect this function to be called a lot";
end cevalInteractiveFunctions3;

annotation(__OpenModelica_Interface="backend");
end CevalScriptBackend;
