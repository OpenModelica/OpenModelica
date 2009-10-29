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

// stefan
package Inline
" file:	       Inline.mo
  package:     Inline
  description: inline functions
  
  RCS: $Id: PartFn.mo 4306 2009-10-06 06:32:29Z sjoelund.se $
  
  This module contains data structures and functions for inline functions.
  
  The entry point is the inlineCalls function, or inlineCallsInFunctions
  "

public import DAE;
public import DAELow;

public function inlineCalls
"function: inlineCalls
	searches for calls where the inline flag is true, and inlines them"
	input DAE.DAElist inDAElist "functions";
	input DAELow.DAELow inDAELow;
  output DAELow.DAELow outDAELow;
algorithm
  outDAELow := inDAELow;
end inlineCalls;

public function inlineCallsInFunctions
"function: inlineCallsInFunctions
	inlines function calls within functions"
	input DAE.DAElist inDAElist;
	output DAE.DAElist outDAElist;
algorithm
  outDAElist := inDAElist;
end inlineCallsInFunctions;









end Inline;