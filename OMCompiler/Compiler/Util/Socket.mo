/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package Socket
" file:        Socket.mo
  package:     Socket
  description: Modelica socket communication module


  This is the socket connection module of the compiler
  Used in interactive mode if omc is started with -d=interactive
  Implemented in ./runtime/soecketimpl.c
  Not implemented in Win32 builds use -d=interactiveCorba instead."

public function waitforconnect
  input Integer inInteger;
  output Integer outInteger;

  external "C" outInteger=Socket_waitforconnect(inInteger) annotation(Library = "omcruntime");
end waitforconnect;

public function handlerequest
  input Integer inInteger;
  output String outString;

  external "C" outString=Socket_handlerequest(inInteger) annotation(Library = "omcruntime");
end handlerequest;

public function sendreply
  input Integer inInteger;
  input String inString;

  external "C" Socket_sendreply(inInteger,inString) annotation(Library = "omcruntime");
end sendreply;

public function close
  input Integer inInteger;

  external "C" Socket_close(inInteger) annotation(Library = "omcruntime");
end close;

public function cleanup

  external "C" Socket_cleanup() annotation(Library = "omcruntime");
end cleanup;

annotation(__OpenModelica_Interface="util");
end Socket;
