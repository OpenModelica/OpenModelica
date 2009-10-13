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

package Settings
" file:	       Settings.mo
  package:     Settings
  description: This file contains settings for omc which are implemented in  C.

  RCS: $Id$
  "

public function getVersionNr "Returns the version number of this release"
  output String outString;

external "C";
end getVersionNr;

public function setCompilePath
  input String inString;

  external "C" ;
end setCompilePath;

public function getCompilePath
  output String outString;

  external "C" ;
end getCompilePath;

public function setCompileCommand
  input String inString;

  external "C" ;
end setCompileCommand;

public function getCompileCommand
  output String outString;

  external "C" ;
end getCompileCommand;

public function setTempDirectoryPath
  input String inString;

  external "C" ;
end setTempDirectoryPath;

public function getTempDirectoryPath
  output String outString;

  external "C" ;
end getTempDirectoryPath;

public function setInstallationDirectoryPath
  input String inString;

  external "C" ;
end setInstallationDirectoryPath;

public function getInstallationDirectoryPath
  output String outString;

  external "C" ;
end getInstallationDirectoryPath;

public function setPlotCommand
  input String inString;

  external "C" ;
end setPlotCommand;

public function getPlotCommand
  output String outString;

  external "C" ;
end getPlotCommand;

public function setModelicaPath
  input String inString;

  external "C" ;
end setModelicaPath;

public function getModelicaPath
  output String outString;

  external "C" ;
end getModelicaPath;

public function getEcho
  output Integer echo;

  external "C" ;
end getEcho;

public function setEcho
  input Integer echo;

  external "C" ;
end setEcho;

public function dumpSettings

  external "C" ;
end dumpSettings;
end Settings;

