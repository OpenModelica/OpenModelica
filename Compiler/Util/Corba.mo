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

encapsulated package Corba
" file:        Corba.mo
  package:     Corba
  description: Modelica Corba communication module


  This is the CORBA connection module of the compiler

  The actual implementation differs between Windows and Unix versions.
  The Windows implementation and the Unix
  version lies in ./runtime but they use C ifdefs to provide different
  implementation

  OpenModelica does not in itself include a complete CORBA implementaton.
  You need to download one, for example MICO from http://www.mico.org.

  There exists some options that can be sent to configure concerning
  the usage of corba:
     --with-omniORB=/location/of/corba/library
     --without-omniORB"

public function haveCorba
  output Boolean b;
  external "C" b=Corba_haveCorba() annotation(Library = {"omcruntime", "OpenModelicaCorba"});
end haveCorba;

public function setObjectReferenceFilePath
  input String inObjectReferenceFilePath;
  external "C" Corba_setObjectReferenceFilePath(inObjectReferenceFilePath) annotation(Library = {"omcruntime", "OpenModelicaCorba"});
end setObjectReferenceFilePath;

public function setSessionName
  input String inSessionName;

  external "C" Corba_setSessionName(inSessionName) annotation(Library = {"omcruntime", "OpenModelicaCorba"});
end setSessionName;

public function initialize

  external "C" Corba_initialize() annotation(Library = {"omcruntime","OpenModelicaCorba"});
end initialize;

public function waitForCommand
  output String outString;

  external "C" outString=Corba_waitForCommand() annotation(Library = {"omcruntime","OpenModelicaCorba"});
end waitForCommand;

public function sendreply
  input String inString;

  external "C" Corba_sendreply(inString) annotation(Library = {"omcruntime","OpenModelicaCorba"});
end sendreply;

public function close

  external "C" Corba_close() annotation(Library = {"omcruntime","OpenModelicaCorba"});
end close;

annotation(__OpenModelica_Interface="util");
end Corba;

