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

encapsulated package Settings
" file:         Settings.mo
  package:     Settings
  description: This file contains settings for omc which are implemented in  C.

  "

public function getVersionNr "Returns the version number of this release"
  output String outString;
external "C" outString=Settings_getVersionNr() annotation(Library = "omcruntime");
end getVersionNr;

public function setCompilePath
  input String inString;
  external "C" SettingsImpl__setCompilePath(inString) annotation(Library = "omcruntime");
end setCompilePath;

/* TODO: Implement an external C function for bootstrapped omc or remove me. DO NOT SIMPLY REMOVE THIS COMMENT
public function getCompilePath
  output String outString;

  external "C" outString=Settings_getCompilePath() annotation(Library = "omcruntime");
end getCompilePath;*/

public function setCompileCommand
  input String inString;

  external "C" SettingsImpl__setCompileCommand(inString) annotation(Library = "omcruntime");
end setCompileCommand;

public function getCompileCommand
  output String outString;

  external "C" outString=Settings_getCompileCommand() annotation(Library = "omcruntime");
end getCompileCommand;

public function setTempDirectoryPath
  input String inString;

  external "C" SettingsImpl__setTempDirectoryPath(inString) annotation(Library = "omcruntime");
end setTempDirectoryPath;

public function getTempDirectoryPath
  output String outString;

  external "C" outString=Settings_getTempDirectoryPath() annotation(Library = "omcruntime");
end getTempDirectoryPath;

public function setInstallationDirectoryPath
  input String inString;

  external "C" SettingsImpl__setInstallationDirectoryPath(inString) annotation(Library = "omcruntime");
end setInstallationDirectoryPath;

public function getInstallationDirectoryPath
  output String outString;
  external "C"  outString=Settings_getInstallationDirectoryPath() annotation(Library = "omcruntime");
end getInstallationDirectoryPath;

public function setModelicaPath
  input String inString;
  external "C" SettingsImpl__setModelicaPath(inString) annotation(Library = "omcruntime");
end setModelicaPath;

public function getModelicaPath
  input Boolean runningTestsuite;
  output String outString;
  external "C" outString=Settings_getModelicaPath(runningTestsuite) annotation(Library = "omcruntime");
end getModelicaPath;

public function getHomeDir
  input Boolean runningTestsuite;
  output String outString;
  external "C" outString=Settings_getHomeDir(runningTestsuite) annotation(Library = "omcruntime");
end getHomeDir;

public function getEcho
  output Integer echo;
  external "C" echo=Settings_getEcho() annotation(Library = "omcruntime");
end getEcho;

public function setEcho
  input Integer echo;
  external "C" Settings_setEcho(echo) annotation(Library = "omcruntime");
end setEcho;

/* TODO: Implement an external C function for bootstrapped omc or remove me. DO NOT SIMPLY REMOVE THIS COMMENT
public function dumpSettings
  external "C" Settings_dumpSettings() annotation(Library = "omcruntime");
end dumpSettings;*/

annotation(__OpenModelica_Interface="util");
end Settings;
