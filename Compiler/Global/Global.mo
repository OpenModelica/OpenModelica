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

encapsulated package Global
" file:        Global.mo
  package:     Global
  description: Global contains structures that are available globally.

  RCS: $Id$

  The Global package contains structures that are available globally."


constant Integer recursionDepthLimit = 256;
constant Integer maxFunctionFileLength = 50;

// hash indexes in global array
constant Integer instHashIndex = 0;
constant Integer typesIndex = 1;
constant Integer crefIndex = 2;
constant Integer builtinIndex = 3;
constant Integer builtinEnvIndex = 4;
constant Integer profilerTime1Index = 5;
constant Integer profilerTime2Index = 6;
constant Integer flagsIndex = 7;
constant Integer builtinGraphEnvIndex = 8;
constant Integer instOnlyForcedFunctions = 9;
constant Integer rewriteRules = 10;

// indexes in System.tick
constant Integer backendDAE_fileSequence = 20;

constant Integer RT_CLOCK_EXECSTAT_MAIN = 11 /* See GlobalScript.mo */;

public function initialize "Called to initialize global roots (when needed)"
algorithm
  setGlobalRoot(instOnlyForcedFunctions,  NONE());
  setGlobalRoot(rewriteRules,  NONE());
end initialize;

end Global;
