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
encapsulated package TaskGraphExt
" file:        TaskGraphExt.mo
  package:     TaskGraphExt
  description: The external representation of a task graph, using Boost Graph Library in C++.

  RCS: $Id$

  This module is the interface to the externally implemented task graph using Boost
  Graph Library in C++"

public function newTask
  input String inString;
  output Integer outInteger;

  external "C" outInteger=TaskGraphExt_newTask(inString) annotation(Library = {"modparomc"});
end newTask;

public function addEdge
  input Integer inInteger1;
  input Integer inInteger2;
  input String inString3;
  input Integer inInteger4;

  external "C" TaskGraphExt_addEdge(inInteger1,inInteger2,inString3,inInteger4) annotation(Library = {"modparomc"});
end addEdge;

public function getTask
  input String inString;
  output Integer outInteger;

  external "C" outInteger=TaskGraphExt_getTask(inString) annotation(Library = {"modparomc"});
end getTask;

public function storeResult
  input String inString1;
  input Integer inInteger2;
  input Boolean inBoolean3;
  input String inString4;

  external "C" TaskGraphExt_storeResult(inString1,inInteger2,inBoolean3,inString4) annotation(Library = {"modparomc"});
end storeResult;

public function dumpGraph
  input String inString;

  external "C" TaskGraphExt_dumpGraph(inString) annotation(Library = {"modparomc"});
end dumpGraph;

public function dumpMergedGraph
  input String inString;

  external "C" TaskGraphExt_dumpMergedGraph(inString) annotation(Library = {"modparomc"});
end dumpMergedGraph;

public function registerStartStop
  input Integer inInteger1;
  input Integer inInteger2;

  external "C" TaskGraphExt_registerStartStop(inInteger1,inInteger2) annotation(Library = {"modparomc"});
end registerStartStop;

/* TODO: Implement an external C function for bootstrapped omc or remove me. DO NOT SIMPLY REMOVE THIS COMMENT
public function getStartTask
  output Integer outInteger;

  external "C" outInteger=TaskGraphExt_getStartTask() annotation(Library = {"modparomc"});
end getStartTask;*/

/* TODO: Implement an external C function for bootstrapped omc or remove me. DO NOT SIMPLY REMOVE THIS COMMENT
public function getStopTask
  output Integer outInteger;

  external "C" outInteger=TaskGraphExt_getStopTask() annotation(Library = {"modparomc"});
end getStopTask;*/

public function mergeTasks
  input Real inReal1;
  input Real inReal2;

  external "C" TaskGraphExt_mergeTasks(inReal1,inReal2) annotation(Library = {"modparomc"});
end mergeTasks;

public function schedule
  input Integer inInteger;

  external "C" TaskGraphExt_schedule(inInteger) annotation(Library = {"modparomc"});
end schedule;

public function generateCode
  input Integer inInteger1;
  input Integer inInteger2;
  input Integer inInteger3;

  external "C" TaskGraphExt_generateCode(inInteger1,inInteger2,inInteger3) annotation(Library = {"modparomc"});
end generateCode;

public function setExecCost
  input Integer inInteger;
  input Real inReal;

  external "C" TaskGraphExt_setExecCost(inInteger,inReal) annotation(Library = {"modparomc"});
end setExecCost;

public function setTaskType
  input Integer inInteger1;
  input Integer inInteger2;

  external "C" TaskGraphExt_setTaskType(inInteger1,inInteger2) annotation(Library = {"modparomc"});
end setTaskType;

public function setCommCost
  input Integer inInteger1;
  input Integer inInteger2;
  input Integer inInteger3;

  external "C" TaskGraphExt_setCommCost(inInteger1,inInteger2,inInteger3) annotation(Library = {"modparomc"});
end setCommCost;

public function addInitVar
  input Integer inInteger1;
  input String inString2;
  input String inString3;

  external "C" TaskGraphExt_addInitVar(inInteger1,inString2,inString3) annotation(Library = {"modparomc"});
end addInitVar;

public function addInitState
  input Integer inInteger1;
  input String inString2;
  input String inString3;

  external "C" TaskGraphExt_addInitState(inInteger1,inString2,inString3) annotation(Library = {"modparomc"});
end addInitState;

public function addInitParam
  input Integer inInteger1;
  input String inString2;
  input String inString3;

  external "C" TaskGraphExt_addInitParam(inInteger1,inString2,inString3) annotation(Library = {"modparomc"});
end addInitParam;
end TaskGraphExt;

