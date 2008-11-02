/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

package TaskGraphExt
" file:	       TaskGraphExt.mo
  package:     TaskGraphExt
  description: The external representation of a task graph, using Boost Graph Library in C++.

  RCS: $Id$

  This module is the interface to the externally implemented task graph using Boost
  Graph Library in C++"

public import Exp;
public import DAELow;

public function newTask
  input String inString;
  output Integer outInteger;

  external "C" ;
end newTask;

public function addEdge
  input Integer inInteger1;
  input Integer inInteger2;
  input String inString3;
  input Integer inInteger4;

  external "C" ;
end addEdge;

public function getTask
  input String inString;
  output Integer outInteger;

  external "C" ;
end getTask;

public function storeResult
  input String inString1;
  input Integer inInteger2;
  input Boolean inBoolean3;
  input String inString4;

  external "C" ;
end storeResult;

public function dumpGraph
  input String inString;

  external "C" ;
end dumpGraph;

public function dumpMergedGraph
  input String inString;

  external "C" ;
end dumpMergedGraph;

public function registerStartStop
  input Integer inInteger1;
  input Integer inInteger2;

  external "C" ;
end registerStartStop;

public function getStartTask
  output Integer outInteger;

  external "C" ;
end getStartTask;

public function getStopTask
  output Integer outInteger;

  external "C" ;
end getStopTask;

public function mergeTasks
  input Real inReal1;
  input Real inReal2;

  external "C" ;
end mergeTasks;

public function schedule
  input Integer inInteger;

  external "C" ;
end schedule;

public function generateCode
  input Integer inInteger1;
  input Integer inInteger2;
  input Integer inInteger3;

  external "C" ;
end generateCode;

public function setExecCost
  input Integer inInteger;
  input Real inReal;

  external "C" ;
end setExecCost;

public function setTaskType
  input Integer inInteger1;
  input Integer inInteger2;

  external "C" ;
end setTaskType;

public function setCommCost
  input Integer inInteger1;
  input Integer inInteger2;
  input Integer inInteger3;

  external "C" ;
end setCommCost;

public function addInitVar
  input Integer inInteger1;
  input String inString2;
  input String inString3;

  external "C" ;
end addInitVar;

public function addInitState
  input Integer inInteger1;
  input String inString2;
  input String inString3;

  external "C" ;
end addInitState;

public function addInitParam
  input Integer inInteger1;
  input String inString2;
  input String inString3;

  external "C" ;
end addInitParam;
end TaskGraphExt;

