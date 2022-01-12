/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
encapsulated package CevalScriptOMSimulator
" file:        CevalScript.mo
  package:     CevalScript
  description: Constant propagation of expressions
  This module handles scripting.
  Input:
    String: Function Name
    Value: Function arguments
  Output:
    Value: The evaluated value."

import Values;
import OMSimulatorExt;

public function ceval
  input String inFunctionName;
  input list<Values.Value> inVals;
  output Values.Value outValue;
algorithm
  (outValue) := matchcontinue (inFunctionName,inVals)
    local
      String cref,crefA,crefB,busCref,connectorCref,stype_,signal,s_lower,s_upper,path,startscript,regex,fmuPath,filenameA,filenameB,var,source,target,filename,initialization,event,simulation,contents,snapshot,newCref,cmd,newTempDir,address,newWorkingDir,version;
      Real stepSize,lower,upper,delay,alpha,linearimpedance,angularimpedance,relTol,absTol,faultValue,loggingInterval,rvalue,startTime,stopTime,x1,x2,x3,A11,A12,A13,A21,A22,A23,A31,A32,A33,absoluteTolerance,relativeTolerance,initialStepSize,minimumStepSize,maximumStepSize;
      Integer status,causality,type_,domain,kind,faultType,ivalue,logLevel,bufferSize,solver,dimensions,interpolation,managerPort,monitorPort;
      Boolean b;

    case ("loadOMSimulator",{})
      equation
        status = OMSimulatorExt.loadOMSimulator();
      then
        Values.INTEGER(status);

    case ("unloadOMSimulator",{})
      equation
        status = OMSimulatorExt.unloadOMSimulator();
      then
        Values.INTEGER(status);

    case("oms_addBus",{Values.STRING(cref)})
      equation
        status = OMSimulatorExt.oms_addBus(cref);
      then
        Values.INTEGER(status);

    case("oms_addConnection",{Values.STRING(crefA), Values.STRING(crefB)})
      equation
        status = OMSimulatorExt.oms_addConnection(crefA,crefB);
      then
        Values.INTEGER(status);

    case("oms_addConnector",{Values.STRING(cref), Values.ENUM_LITERAL(index=causality), Values.ENUM_LITERAL(index=type_)})
      equation
        status = OMSimulatorExt.oms_addConnector(cref,causality-1,type_-1);
      then
        Values.INTEGER(status);

    case("oms_addConnectorToBus",{Values.STRING(busCref), Values.STRING(connectorCref)})
      equation
        status = OMSimulatorExt.oms_addConnectorToBus(busCref,connectorCref);
      then
        Values.INTEGER(status);

    case("oms_addConnectorToTLMBus",{Values.STRING(busCref), Values.STRING(connectorCref), Values.STRING(stype_)})
      equation
        status = OMSimulatorExt.oms_addConnectorToTLMBus(busCref,connectorCref,stype_);
      then
        Values.INTEGER(status);

    case("oms_addDynamicValueIndicator",{Values.STRING(signal), Values.STRING(s_lower), Values.STRING(s_upper), Values.REAL(stepSize)})
      equation
        status = OMSimulatorExt.oms_addDynamicValueIndicator(signal,s_lower,s_upper,stepSize);
      then
        Values.INTEGER(status);

    case("oms_addEventIndicator",{Values.STRING(signal)})
      equation
        status = OMSimulatorExt.oms_addEventIndicator(signal);
      then
        Values.INTEGER(status);

    case("oms_addExternalModel",{Values.STRING(cref), Values.STRING(path), Values.STRING(startscript)})
      equation
        status = OMSimulatorExt.oms_addExternalModel(cref,path,startscript);
      then
        Values.INTEGER(status);

    case("oms_addSignalsToResults",{Values.STRING(cref), Values.STRING(regex)})
      equation
        status = OMSimulatorExt.oms_addSignalsToResults(cref,regex);
      then
        Values.INTEGER(status);

    case("oms_addStaticValueIndicator",{Values.STRING(signal), Values.REAL(lower), Values.REAL(upper), Values.REAL(stepSize)})
      equation
        status = OMSimulatorExt.oms_addStaticValueIndicator(signal,lower,upper,stepSize);
      then
        Values.INTEGER(status);

    case("oms_addSubModel",{Values.STRING(cref), Values.STRING(fmuPath)})
      equation
        status = OMSimulatorExt.oms_addSubModel(cref,fmuPath);
      then
        Values.INTEGER(status);

    case("oms_addSystem",{Values.STRING(cref), Values.ENUM_LITERAL(index=type_)})
      equation
        status = OMSimulatorExt.oms_addSystem(cref,type_-1);
      then
        Values.INTEGER(status);

    case("oms_addTimeIndicator",{Values.STRING(signal)})
      equation
        status = OMSimulatorExt.oms_addTimeIndicator(signal);
      then
        Values.INTEGER(status);

    case("oms_addTLMBus",{Values.STRING(cref), Values.ENUM_LITERAL(index=domain), Values.INTEGER(dimensions),Values.ENUM_LITERAL(index=interpolation)})
      equation
        status = OMSimulatorExt.oms_addTLMBus(cref,(domain-1),dimensions,(interpolation-1));
      then
        Values.INTEGER(status);

    case("oms_addTLMConnection",{Values.STRING(crefA), Values.STRING(crefB), Values.REAL(delay), Values.REAL(alpha), Values.REAL(linearimpedance), Values.REAL(angularimpedance)})
      equation
        status = OMSimulatorExt.oms_addTLMConnection(crefA,crefB,delay,alpha,linearimpedance,angularimpedance);
      then
        Values.INTEGER(status);

    case("oms_compareSimulationResults",{Values.STRING(filenameA), Values.STRING(filenameB), Values.STRING(var), Values.REAL(relTol), Values.REAL(absTol)})
      equation
        status = OMSimulatorExt.oms_compareSimulationResults(filenameA,filenameB,var,relTol,absTol);
      then
        Values.INTEGER(status);

    case("oms_copySystem",{Values.STRING(source), Values.STRING(target)})
      equation
        status = OMSimulatorExt.oms_copySystem(source,target);
      then
        Values.INTEGER(status);

    case("oms_delete",{Values.STRING(cref)})
      equation
        status = OMSimulatorExt.oms_delete(cref);
      then
        Values.INTEGER(status);

    case("oms_deleteConnection",{Values.STRING(crefA), Values.STRING(crefB)})
      equation
        status = OMSimulatorExt.oms_deleteConnection(crefA,crefB);
      then
        Values.INTEGER(status);

    case("oms_deleteConnectorFromBus",{Values.STRING(busCref), Values.STRING(connectorCref)})
      equation
        status = OMSimulatorExt.oms_deleteConnectorFromBus(busCref,connectorCref);
      then
        Values.INTEGER(status);

    case("oms_deleteConnectorFromTLMBus",{Values.STRING(busCref), Values.STRING(connectorCref)})
      equation
        status = OMSimulatorExt.oms_deleteConnectorFromTLMBus(busCref,connectorCref);
      then
        Values.INTEGER(status);

    case("oms_export",{Values.STRING(cref), Values.STRING(filename)})
      equation
        status = OMSimulatorExt.oms_export(cref,filename);
      then
        Values.INTEGER(status);

    case("oms_exportDependencyGraphs",{Values.STRING(cref), Values.STRING(initialization), Values.STRING(event), Values.STRING(simulation)})
      equation
        status = OMSimulatorExt.oms_exportDependencyGraphs(cref,initialization,event,simulation);
      then
        Values.INTEGER(status);

    case("oms_exportSnapshot",{Values.STRING(cref)})
      equation
        (contents,status) = OMSimulatorExt.oms_exportSnapshot(cref);
      then
        Values.TUPLE({Values.STRING(contents),Values.INTEGER(status)});

    case("oms_extractFMIKind",{Values.STRING(filename)})
      equation
        (kind,status) = OMSimulatorExt.oms_extractFMIKind(filename);
      then
        Values.TUPLE({Values.INTEGER(kind),Values.INTEGER(status)});

    case("oms_getBoolean",{Values.STRING(cref)})
      equation
        (b,status) = OMSimulatorExt.oms_getBoolean(cref);
      then
        Values.TUPLE({Values.BOOL(b),Values.INTEGER(status)});

    case("oms_getFixedStepSize",{Values.STRING(cref)})
      equation
        (rvalue,status) = OMSimulatorExt.oms_getFixedStepSize(cref);
      then
        Values.TUPLE({Values.REAL(rvalue),Values.INTEGER(status)});

    case("oms_getInteger",{Values.STRING(cref)})
      equation
        (ivalue,status) = OMSimulatorExt.oms_getInteger(cref);
      then
        Values.TUPLE({Values.INTEGER(ivalue),Values.INTEGER(status)});

    case("oms_getModelState",{Values.STRING(cref)})
      equation
        (ivalue,status) = OMSimulatorExt.oms_getModelState(cref);
      then
        Values.TUPLE({Values.INTEGER(ivalue),Values.INTEGER(status)});

    case("oms_getReal",{Values.STRING(cref)})
      equation
        (rvalue,status) = OMSimulatorExt.oms_getReal(cref);
      then
        Values.TUPLE({Values.REAL(rvalue),Values.INTEGER(status)});

    case("oms_getSolver",{Values.STRING(cref)})
      equation
        (ivalue,status) = OMSimulatorExt.oms_getSolver(cref);
      then
        Values.TUPLE({Values.INTEGER(ivalue),Values.INTEGER(status)});

    case("oms_getStartTime",{Values.STRING(cref)})
      equation
        (rvalue,status) = OMSimulatorExt.oms_getStartTime(cref);
      then
        Values.TUPLE({Values.REAL(rvalue),Values.INTEGER(status)});

    case("oms_getStopTime",{Values.STRING(cref)})
      equation
        (rvalue,status) = OMSimulatorExt.oms_getStopTime(cref);
      then
        Values.TUPLE({Values.REAL(rvalue),Values.INTEGER(status)});

    case("oms_getSubModelPath",{Values.STRING(cref)})
      equation
        (path,status) = OMSimulatorExt.oms_getSubModelPath(cref);
      then
        Values.TUPLE({Values.STRING(path),Values.INTEGER(status)});

    case("oms_getSystemType",{Values.STRING(cref)})
      equation
        (ivalue,status) = OMSimulatorExt.oms_getSystemType(cref);
      then
        Values.TUPLE({Values.INTEGER(ivalue),Values.INTEGER(status)});

    case("oms_getTolerance",{Values.STRING(cref)})
      equation
        (absoluteTolerance,relativeTolerance,status) = OMSimulatorExt.oms_getTolerance(cref);
      then
        Values.TUPLE({Values.REAL(absoluteTolerance),Values.REAL(relativeTolerance),Values.INTEGER(status)});

    case("oms_getVariableStepSize",{Values.STRING(cref)})
      equation
        (initialStepSize,minimumStepSize,maximumStepSize,status) = OMSimulatorExt.oms_getVariableStepSize(cref);
      then
        Values.TUPLE({Values.REAL(initialStepSize),Values.REAL(minimumStepSize),Values.REAL(maximumStepSize),Values.INTEGER(status)});

    case("oms_faultInjection",{Values.STRING(signal), Values.ENUM_LITERAL(index=faultType), Values.REAL(faultValue)})
      equation
        status = OMSimulatorExt.oms_faultInjection(signal,faultType-1,faultValue);
      then
        Values.INTEGER(status);

    case("oms_importFile",{Values.STRING(filename)})
      equation
        (cref,status) = OMSimulatorExt.oms_importFile(filename);
      then
        Values.TUPLE({Values.STRING(cref),Values.INTEGER(status)});

    case("oms_importSnapshot",{Values.STRING(cref), Values.STRING(snapshot)})
      equation
        status = OMSimulatorExt.oms_importSnapshot(cref,snapshot);
      then
        Values.INTEGER(status);

    case("oms_initialize",{Values.STRING(cref)})
      equation
        status = OMSimulatorExt.oms_initialize(cref);
      then
        Values.INTEGER(status);

    case("oms_instantiate",{Values.STRING(cref)})
      equation
        status = OMSimulatorExt.oms_instantiate(cref);
      then
        Values.INTEGER(status);

    case("oms_list",{Values.STRING(cref)})
      equation
        (contents,status) = OMSimulatorExt.oms_list(cref);
      then
        Values.TUPLE({Values.STRING(contents),Values.INTEGER(status)});

    case("oms_listUnconnectedConnectors",{Values.STRING(cref)})
      equation
        (contents,status) = OMSimulatorExt.oms_listUnconnectedConnectors(cref);
      then
        Values.TUPLE({Values.STRING(contents),Values.INTEGER(status)});

    case("oms_loadSnapshot",{Values.STRING(cref), Values.STRING(snapshot)})
      equation
        (newCref,status) = OMSimulatorExt.oms_loadSnapshot(cref,snapshot);
      then
        Values.TUPLE({Values.STRING(newCref),Values.INTEGER(status)});

    case("oms_newModel",{Values.STRING(cref)})
      equation
        status = OMSimulatorExt.oms_newModel(cref);
      then
        Values.INTEGER(status);

    case("oms_removeSignalsFromResults",{Values.STRING(cref), Values.STRING(regex)})
      equation
        status = OMSimulatorExt.oms_removeSignalsFromResults(cref,regex);
      then
        Values.INTEGER(status);

    case("oms_rename",{Values.STRING(cref), Values.STRING(newCref)})
      equation
        status = OMSimulatorExt.oms_rename(cref,newCref);
      then
        Values.INTEGER(status);

    case("oms_reset",{Values.STRING(cref)})
      equation
        status = OMSimulatorExt.oms_reset(cref);
      then
        Values.INTEGER(status);

    case("oms_RunFile",{Values.STRING(filename)})
      equation
        status = OMSimulatorExt.oms_RunFile(filename);
      then
        Values.INTEGER(status);

    case("oms_setBoolean",{Values.STRING(cref),Values.BOOL(b)})
      equation
        status = OMSimulatorExt.oms_setBoolean(cref,b);
      then
        Values.INTEGER(status);

    case("oms_setCommandLineOption",{Values.STRING(cmd)})
      equation
        status = OMSimulatorExt.oms_setCommandLineOption(cmd);
      then
        Values.INTEGER(status);

    case("oms_setFixedStepSize",{Values.STRING(cref), Values.REAL(stepSize)})
      equation
        status = OMSimulatorExt.oms_setFixedStepSize(cref,stepSize);
      then
        Values.INTEGER(status);

    case("oms_setInteger",{Values.STRING(cref), Values.INTEGER(ivalue)})
      equation
        status = OMSimulatorExt.oms_setInteger(cref,ivalue);
      then
        Values.INTEGER(status);

    case("oms_setLogFile",{Values.STRING(filename)})
      equation
        status = OMSimulatorExt.oms_setLogFile(filename);
      then
        Values.INTEGER(status);

    case("oms_setLoggingInterval",{Values.STRING(cref), Values.REAL(loggingInterval)})
      equation
        status = OMSimulatorExt.oms_setLoggingInterval(cref,loggingInterval);
      then
        Values.INTEGER(status);

    case("oms_setLoggingLevel",{Values.INTEGER(logLevel)})
      equation
        status = OMSimulatorExt.oms_setLoggingLevel(logLevel);
      then
        Values.INTEGER(status);

    case("oms_setReal",{Values.STRING(cref), Values.REAL(rvalue)})
      equation
        status = OMSimulatorExt.oms_setReal(cref,rvalue);
      then
        Values.INTEGER(status);

    case("oms_setRealInputDerivative",{Values.STRING(cref), Values.REAL(rvalue)})
      equation
        status = OMSimulatorExt.oms_setRealInputDerivative(cref,rvalue);
      then
        Values.INTEGER(status);

    case("oms_setResultFile",{Values.STRING(cref), Values.STRING(filename), Values.INTEGER(bufferSize)})
      equation
        status = OMSimulatorExt.oms_setResultFile(cref,filename,bufferSize);
      then
        Values.INTEGER(status);

    case("oms_setSignalFilter",{Values.STRING(cref), Values.STRING(regex)})
      equation
        status = OMSimulatorExt.oms_setSignalFilter(cref,regex);
      then
        Values.INTEGER(status);

    case("oms_setSolver",{Values.STRING(cref), Values.ENUM_LITERAL(index=solver)})
      equation
        status = OMSimulatorExt.oms_setSolver(cref,solver-1);
      then
        Values.INTEGER(status);

    case("oms_setStartTime",{Values.STRING(cref), Values.REAL(startTime)})
      equation
        status = OMSimulatorExt.oms_setStartTime(cref,startTime);
      then
        Values.INTEGER(status);

    case("oms_setStopTime",{Values.STRING(cref), Values.REAL(stopTime)})
      equation
        status = OMSimulatorExt.oms_setStopTime(cref,stopTime);
      then
        Values.INTEGER(status);

    case("oms_setTempDirectory",{Values.STRING(newTempDir)})
      equation
        status = OMSimulatorExt.oms_setTempDirectory(newTempDir);
      then
        Values.INTEGER(status);

    case("oms_setTLMPositionAndOrientation",{Values.STRING(cref), Values.REAL(x1), Values.REAL(x2), Values.REAL(x3), Values.REAL(A11), Values.REAL(A12), Values.REAL(A13), Values.REAL(A21), Values.REAL(A22), Values.REAL(A23), Values.REAL(A31), Values.REAL(A32), Values.REAL(A33)})
      equation
        status = OMSimulatorExt.oms_setTLMPositionAndOrientation(cref,x1,x2,x3,A11,A12,A13,A21,A22,A23,A31,A32,A33);
      then
        Values.INTEGER(status);

    case("oms_setTLMSocketData",{Values.STRING(cref), Values.STRING(address), Values.INTEGER(managerPort), Values.INTEGER(monitorPort)})
      equation
        status = OMSimulatorExt.oms_setTLMSocketData(cref,address,managerPort,monitorPort);
      then
        Values.INTEGER(status);

    case("oms_setTolerance",{Values.STRING(cref), Values.REAL(absoluteTolerance), Values.REAL(relativeTolerance)})
      equation
        status = OMSimulatorExt.oms_setTolerance(cref,absoluteTolerance,relativeTolerance);
      then
        Values.INTEGER(status);

    case("oms_setVariableStepSize",{Values.STRING(cref), Values.REAL(initialStepSize), Values.REAL(minimumStepSize), Values.REAL(maximumStepSize)})
      equation
        status = OMSimulatorExt.oms_setVariableStepSize(cref,initialStepSize,minimumStepSize,maximumStepSize);
      then
        Values.INTEGER(status);

    case("oms_setWorkingDirectory",{Values.STRING(newWorkingDir)})
      equation
        status = OMSimulatorExt.oms_setWorkingDirectory(newWorkingDir);
      then
        Values.INTEGER(status);

    case("oms_simulate",{Values.STRING(cref)})
      equation
        status = OMSimulatorExt.oms_simulate(cref);
      then
        Values.INTEGER(status);

    case("oms_stepUntil",{Values.STRING(cref), Values.REAL(stopTime)})
      equation
        status = OMSimulatorExt.oms_stepUntil(cref,stopTime);
      then
        Values.INTEGER(status);

    case("oms_terminate",{Values.STRING(cref)})
      equation
        status = OMSimulatorExt.oms_terminate(cref);
      then
        Values.INTEGER(status);

    case ("oms_getVersion",{})
      equation
        version = OMSimulatorExt.oms_getVersion();
      then
        Values.STRING(version);
  end matchcontinue;
end ceval;
annotation(__OpenModelica_Interface="backend");
end CevalScriptOMSimulator;
