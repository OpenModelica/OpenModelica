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
 
package Socket 
" file:        Socket.mo
  package:     Socket
  description: Modelica socket communication module
 
  RCS: $Id$
 
  This is the socket connection module of the compiler
  Used in interactive mode if omc is started with +d=interactive
  Implemented in ./runtime/soecketimpl.c
  Not implemented in Win32 builds use +d=interactiveCorba instead."

public function waitforconnect
  input Integer inInteger;
  output Integer outInteger;

  external "C" ;
end waitforconnect;

public function handlerequest
  input Integer inInteger;
  output String outString;

  external "C" ;
end handlerequest;

public function sendreply
  input Integer inInteger;
  input String inString;

  external "C" ;
end sendreply;

public function close
  input Integer inInteger;

  external "C" ;
end close;

public function cleanup

  external "C" ;
end cleanup;
end Socket;

