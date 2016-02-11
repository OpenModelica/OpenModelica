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

encapsulated package Debug
" file:        Debug.mo
  package:     Debug
  description: Debug printing


  Printing routines for debug output of strings. Also flag controlled
  printing. When flag controlled printing functions are called, printing is
  done only if the given flag is among the flags given in the runtime
  arguments, to +d-flag, i.e. if +d=inst,lookup is given in the command line,
  only calls containing these flags will actually print something, e.g.:
  fprint(\"inst\", \"Starting instantiation...\"). See runtime/rtopts.c for
  implementation of flag checking."

protected import Print;

public function trace "used for debug printing."
  input String s;
algorithm
  Print.printErrorBuf(s);
end trace;

public function traceln "printing with newline."
  input String str;
algorithm
  Print.printErrorBuf(str);
  Print.printErrorBuf("\n");
end traceln;

annotation(__OpenModelica_Interface="util");
end Debug;
