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

package Parser
" file:	       Parser.mo
  package:     Parser
  description: Interface to external code for parsing

  $Id$

  The parser module is used for both parsing of files and statements in
  interactive mode. Some functions never fails, even if parsing fails. Instead,
  they return an error message other than \"Ok\".

  Input: String to parse
  Output: Absyn.Program or InteractiveStmts"

public import Absyn;
public import Interactive;

public function parse
  input String inString;
  output Absyn.Program outProgram;

  external "C" ;
end parse;

public function parseexp
  input String inString;
  output Interactive.InteractiveStmts outInteractiveStmts;

  external "C" ;
end parseexp;

public function parsestring
  input String inString;
  output Absyn.Program outProgram;
  output String outString;

  external "C" ;
end parsestring;

public function parsestringexp
  input String inString;
  output Interactive.InteractiveStmts outInteractiveStmts;
  output String outString;

  external "C" ;
end parsestringexp;
end Parser;

