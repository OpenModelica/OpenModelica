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

#include "settingsimpl.c"

extern "C" {

extern const char* Settings_getInstallationDirectoryPath()
{
  const char *path = SettingsImpl__getInstallationDirectoryPath();
  if (path == NULL)
    throw 1;
  return strdup(path);
}

extern const char* Settings_getModelicaPath()
{
  const char *path = SettingsImpl__getModelicaPath();
  if (path == NULL)
    throw 1;
  return path;
}

extern const char* Settings_getCompileCommand()
{
  return strdup(SettingsImpl__getCompileCommand());
}

extern void Settings_setPlotCommand(const char* _inString);

extern int Settings_getEcho()
{
  return echo;
}

extern void Settings_setEcho(int _echo)
{
  echo = _echo;
}

extern const char* Settings_getVersionNr()
{
  return CONFIG_VERSION;
}

extern const char* Settings_getTempDirectoryPath()
{
  return strdup(SettingsImpl__getTempDirectoryPath());
}

}
