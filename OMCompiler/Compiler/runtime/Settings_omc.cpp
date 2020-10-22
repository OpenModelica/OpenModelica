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

#include <string>

#if defined(_MSC_VER) || defined(__MINGW32__)
 #define WIN32_LEAN_AND_MEAN
 #include <windows.h>
#endif

#include "meta/meta_modelica.h"

extern "C" {

#include "settingsimpl.c"
#include "ModelicaUtilities.h"

extern const char* Settings_getInstallationDirectoryPath()
{
  const char *path = SettingsImpl__getInstallationDirectoryPath();
  if (path == NULL)
    MMC_THROW();
  return path;
}

extern const char* Settings_getModelicaPath(int runningTestsuite)
{
  const char *path = SettingsImpl__getModelicaPath(runningTestsuite);
  if (path == NULL)
    MMC_THROW();
  return path;
}

extern const char* Settings_getCompileCommand()
{
  const char *res = SettingsImpl__getCompileCommand();
  return strcpy(ModelicaAllocateString(strlen(res)), res);
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
  return SettingsImpl__getTempDirectoryPath();
}

}
