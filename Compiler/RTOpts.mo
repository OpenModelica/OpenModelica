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

  external "C" ;
end args;

public function typeinfo
  output Boolean outBoolean;

  external "C" ;
end typeinfo;

public function splitArrays
  output Boolean outBoolean;

  external "C" ;
end splitArrays;

public function paramsStruct
  output Boolean outBoolean;

  external "C" ;
end paramsStruct;

public function modelicaOutput
  output Boolean outBoolean;

  external "C" ;
end modelicaOutput;

public function debugFlag
  input String inString;
  output Boolean outBoolean;

  external "C" ;
end debugFlag;

public function setDebugFlag
  input String inString;
  input Integer value;
  output Boolean str;

  external "C" ;
end setDebugFlag;

public function noProc
  output Integer outInteger;

  external "C" ;
end noProc;

public function setEliminationLevel
  input Integer level;

  external "C" ;
end setEliminationLevel;

public function eliminationLevel
  output Integer level;

  external "C" ;
end eliminationLevel;

public function latency
  output Real outReal;

  external "C" ;
end latency;

public function bandwidth
  output Real outReal;

  external "C" ;
end bandwidth;

public function simulationCg
  output Boolean outBoolean;

  external "C" ;
end simulationCg;

public function simulationCodeTarget
"@author: adrpo
 returns: 'gcc' or 'msvc'
 usage: omc [+target=gcc|msvc], default to 'gcc'."
  output String outCodeTarget;

  external "C" ;
end simulationCodeTarget;

public function classToInstantiate
  output String modelName;

  external "C";
end classToInstantiate;

public function silent
  output Boolean outBoolean;

  external "C" ;
end silent;

public function versionRequest
  output Boolean outBoolean;

  external "C";
  end versionRequest;

public function acceptMetaModelicaGrammar
"@author: adrpo 2007-06-11
 returns: true if MetaModelica grammar is accepted or false otherwise
 usage: omc [+g=Modelica|MetaModelica], default to 'Modelica'."
  output Boolean outBoolean;

  external "C";
end acceptMetaModelicaGrammar;

public function getAnnotationVersion
"@author: adrpo 2008-11-28
   returns what flag was given at start
     omc [+annotationVersion=3.x]
   or via the API
     setAnnotationVersion(\"3.x\");
   for annotations: 1.x or 2.x or 3.x"
  output String annotationVersion;
  external "C";
end getAnnotationVersion;

public function setAnnotationVersion
"@author: adrpo 2008-11-28
   setAnnotationVersion(\"3.x\");
   for annotations: 1.x or 2.x or 3.x"
  input String annotationVersion;
  external "C";
end setAnnotationVersion;

public function getNoSimplify
"@author: adrpo 2008-12-13
   returns what flag was given at start
     omc [+noSimplify]
   or via the API
     setNoSimplify(true|false);"
  output Boolean noSimplify;
  external "C";
end getNoSimplify;

public function setNoSimplify
"@author: adrpo 2008-12-13
   setAnnotationVersion(\"3.x\");
   for annotations: 1.x or 2.x or 3.x"
  input Boolean noSimplify;
  external "C";
end setNoSimplify;

public function vectorizationLimit
  "Returns the vectorization limit that is used to determine how large an array
  can be before it no longer is expanded by Static.crefVectorize."
  output Integer limit;
  external "C";
end vectorizationLimit;

public function setVectorizationLimit
  "Sets the vectorization limit, see vectorizationLimit above."
  input Integer limit;
  external "C";
end setVectorizationLimit;

public function showAnnotations
  output Boolean show;
  external "C";
end showAnnotations;

public function setShowAnnotations
  input Boolean show;
  external "C";
end setShowAnnotations;

end RTOpts;

