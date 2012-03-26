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

#if defined(_MSC_VER)
#include <Windows.h>
#endif

#include "meta_modelica.h"

extern "C" {

#include "settingsimpl.c"

extern const char* Settings_getInstallationDirectoryPath()
{
  const char *path = SettingsImpl__getInstallationDirectoryPath();
  if (path == NULL)
    MMC_THROW();
  return strdup(path);
}

extern const char* Settings_getModelicaPath()
{
  const char *path = SettingsImpl__getModelicaPath();
  if (path == NULL)
    MMC_THROW();
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

static const std::string version = std::string(CONFIG_VERSION) + std::string(" (Bootstrapping version; only for development)");

extern const char* Settings_getVersionNr()
{
  return version.c_str();
}

extern const char* Settings_getTempDirectoryPath()
{
  return SettingsImpl__getTempDirectoryPath();
}

}
