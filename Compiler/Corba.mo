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

package Corba
" file:        Corba.mo
  package:      Corba
  description: Modelica Corba communication module

  RCS: $Id$

  This is the CORBA connection module of the compiler

  The actual implementation differs between Windows and Unix versions.
  The Windows implementation and the Unix
  version lies in ./runtime but they use C ifdefs to provide different
  implementation

  OpenModelica does not in itself include a complete CORBA implementaton.
  You need to download one, for example MICO from http://www.mico.org.

  There exists some options that can be sent to configure concerinng
  the usage of corba:
     --with-CORBA=/location/of/corba/library
     --without-CORBA"

public function initialize

  external "C" ;
end initialize;

public function waitForCommand
  output String outString;

  external "C" ;
end waitForCommand;

public function sendreply
  input String inString;

  external "C" ;
end sendreply;

public function close

  external "C" ;
end close;
end Corba;

