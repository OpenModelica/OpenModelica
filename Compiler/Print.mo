/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
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

package Print
" file:        Print.mo
  package:     Print
  description: Printing to buffers

  RCS: $Id$

  This module contains a buffered print function to be used instead of
  the built in print function, when the output should be redirected to
  some other place. It also contains print functions for error messages, to be
  used in interactive mode."

public function setBufSize 
  input Integer newSize;

  external "C" ;
end setBufSize;

public function unSetBufSize 
  input Integer newSize "not used, this is a debuging func"; 

  external "C" ;
end unSetBufSize;
  
public function printErrorBuf
  input String inString;

  external "C" ;
end printErrorBuf;

public function clearErrorBuf

  external "C" ;
end clearErrorBuf;

public function getErrorString
  output String outString;

  external "C" ;
end getErrorString;

public function printBuf
  input String inString;

  external "C" ;
end printBuf;

public function clearBuf

  external "C" ;
end clearBuf;

public function getString
  output String outString;

  external "C" ;
end getString;

public function writeBuf
  input String inString;

  external "C" ;
end writeBuf;
end Print;

