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

package RTOpts
" file:	       RTOpts.mo
  package:     RTOpts
  description: Runtime options

  RCS: $Id$

  This module takes care of command line options. It is possible to
  ask it what flags are set, what arguments were given etc.

  This module is used pretty much everywhere where debug calls are made."


public function args
  input list<String> inStringLst;
  output list<String> outStringLst;

  external "C" outStringLst=RTOpts_args(inStringLst) annotation(Library = "omcruntime");
end args;

public function typeinfo
  output Boolean outBoolean;

  external "C" outBoolean = RTOpts_typeinfo() annotation(Library = "omcruntime");
end typeinfo;

public function splitArrays
  output Boolean outBoolean;

  external "C" outBoolean = RTOpts_splitArrays() annotation(Library = "omcruntime");
end splitArrays;

public function paramsStruct
  output Boolean outBoolean;

  external "C" outBoolean = RTOpts_paramsStruct() annotation(Library = "omcruntime");
end paramsStruct;

public function modelicaOutput
  output Boolean outBoolean;

  external "C" outBoolean = RTOpts_modelicaOutput() annotation(Library = "omcruntime");
end modelicaOutput;

public function debugFlag
  input String inString;
  output Boolean outBoolean;

  external "C" outBoolean=RTOpts_debugFlag(inString) annotation(Library = "omcruntime");
end debugFlag;

public function setDebugFlag
  input String inString;
  input Integer value;
  output Boolean str;

  external "C" str = RTOpts_setDebugFlag(inString,value) annotation(Library = "omcruntime");
end setDebugFlag;

public function noProc
  output Integer outInteger;

  external "C" outInteger = RTOpts_noProc() annotation(Library = "omcruntime");
end noProc;

public function setEliminationLevel
  input Integer level;

  external "C" RTOpts_setEliminationLevel(level) annotation(Library = "omcruntime");
end setEliminationLevel;

public function eliminationLevel
  output Integer level;

  external "C" level = RTOpts_level() annotation(Library = "omcruntime");
end eliminationLevel;

public function latency
  output Real outReal;

  external "C" outReal = RTOpts_latency() annotation(Library = "omcruntime");
end latency;

public function bandwidth
  output Real outReal;

  external "C" outReal = RTOpts_bandwidth() annotation(Library = "omcruntime");
end bandwidth;

public function simulationCg
  output Boolean outBoolean;

  external "C" outBoolean = RTOpts_simulationCg() annotation(Library = "omcruntime");
end simulationCg;

public function simulationCodeTarget
"@author: adrpo
 returns: 'gcc' or 'msvc'
 usage: omc [+target=gcc|msvc], default to 'gcc'."
  output String outCodeTarget;

  external "C" outCodeTarget = RTOpts_simulationCodeTarget() annotation(Library = "omcruntime");
end simulationCodeTarget;

public function classToInstantiate
  output String modelName;

  external "C" modelName = RTOpts_classToInstantiate() annotation(Library = "omcruntime");
end classToInstantiate;

public function silent
  output Boolean outBoolean;

  external "C" outBoolean = RTOpts_silent() annotation(Library = "omcruntime");
end silent;

public function versionRequest
  output Boolean outBoolean;

  external "C" outBoolean = RTOpts_versionRequest() annotation(Library = "omcruntime");
end versionRequest;

public function acceptMetaModelicaGrammar
"@author: adrpo 2007-06-11
 returns: true if MetaModelica grammar is accepted or false otherwise
 usage: omc [+g=Modelica|MetaModelica], default to 'Modelica'."
  output Boolean outBoolean;

  external "C" outBoolean = RTOpts_acceptMetaModelicaGrammar() annotation(Library = "omcruntime");
end acceptMetaModelicaGrammar;

public function getAnnotationVersion
"@author: adrpo 2008-11-28
   returns what flag was given at start
     omc [+annotationVersion=3.x]
   or via the API
     setAnnotationVersion(\"3.x\");
   for annotations: 1.x or 2.x or 3.x"
  output String annotationVersion;
  external "C" annotationVersion = RTOpts_getAnnotationVersion() annotation(Library = "omcruntime");
end getAnnotationVersion;

public function setAnnotationVersion
"@author: adrpo 2008-11-28
   setAnnotationVersion(\"3.x\");
   for annotations: 1.x or 2.x or 3.x"
  input String annotationVersion;
  external "C" RTOpts_setAnnotationVersion(annotationVersion) annotation(Library = "omcruntime");
end setAnnotationVersion;

public function getNoSimplify
"@author: adrpo 2008-12-13
   returns what flag was given at start
     omc [+noSimplify]
   or via the API
     setNoSimplify(true|false);"
  output Boolean noSimplify;
  external "C" noSimplify = RTOpts_getNoSimplify() annotation(Library = "omcruntime");
end getNoSimplify;

public function setNoSimplify
  input Boolean noSimplify;
  external "C" RTOpts_setNoSimplify(noSimplify) annotation(Library = "omcruntime");
end setNoSimplify;

public function vectorizationLimit
  "Returns the vectorization limit that is used to determine how large an array
  can be before it no longer is expanded by Static.crefVectorize."
  output Integer limit;
  external "C" limit = RTOpts_vectorizationLimit() annotation(Library = "omcruntime");
end vectorizationLimit;

public function setVectorizationLimit
  "Sets the vectorization limit, see vectorizationLimit above."
  input Integer limit;
  external "C" RTOpts_setVectorizationLimit(limit) annotation(Library = "omcruntime");
end setVectorizationLimit;

public function showAnnotations
  output Boolean show;
  external "C" show = RTOpts_showAnnotations() annotation(Library = "omcruntime");
end showAnnotations;

public function setShowAnnotations
  input Boolean show;
  external "C" RTOpts_setShowAnnotations(show) annotation(Library = "omcruntime");
end setShowAnnotations;

public function getRunningTestsuite
  output Boolean runningTestsuite;
  external "C" runningTestsuite = RTOpts_getRunningTestsuite() annotation(Library = "omcruntime");
end getRunningTestsuite;

public function getEvaluateParametersInAnnotations
"@author: adrpo
 flag to tell us if we should evaluate parameters in annotations"
 output Boolean shouldEvaluate; 
 external "C" shouldEvaluate=RTOpts_getEvaluateParametersInAnnotations() annotation(Library = "omcruntime");
end getEvaluateParametersInAnnotations;

public function setEvaluateParametersInAnnotations
"@author: adrpo
 flag to tell us if we should evaluate parameters in annotations"
 input Boolean shouldEvaluate; 
 external "C" RTOpts_setEvaluateParametersInAnnotations(shouldEvaluate) annotation(Library = "omcruntime");
end setEvaluateParametersInAnnotations;

end RTOpts;

