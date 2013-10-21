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
#include "rml.h"

void Settings_5finit(void)
{
}


RML_BEGIN_LABEL(Settings__getVersionNr)
{
  rmlA0 = (void*) mk_scon(CONFIG_VERSION " (RML version)");
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Settings__setCompileCommand)
{
  char* command = RML_STRINGDATA(rmlA0);
  if(compileCommand)
    free(compileCommand);
  compileCommand = (char*)malloc(strlen(command)+1);
  if (compileCommand == NULL) {
    RML_TAILCALLK(rmlFC);
  }
  memcpy(compileCommand,command,strlen(command)+1);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Settings__getCompileCommand)
{
  rmlA0 = mk_scon(SettingsImpl__getCompileCommand());
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Settings__setCompilePath)
{
  char* command = RML_STRINGDATA(rmlA0);
  if(compilePath)
    free(compilePath);

  compilePath = (char*)malloc(strlen(command)+1);
  if (compilePath == NULL) {
    RML_TAILCALLK(rmlFC);
  }
  memcpy(compilePath,command,strlen(command)+1);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Settings__getCompilePath)
{
  rmlA0 = mk_scon(SettingsImpl__getCompilePath());
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Settings__setTempDirectoryPath)
{
  const char* command = RML_STRINGDATA(rmlA0);
  SettingsImpl__setTempDirectoryPath(command);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Settings__getTempDirectoryPath)
{
  const char *tdp = SettingsImpl__getTempDirectoryPath();
  if (tdp)
    rmlA0 = (void*) mk_scon(tdp);
  else
    rmlA0 = (void*) mk_scon("");
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Settings__setInstallationDirectoryPath)
{
  const char* command = RML_STRINGDATA(rmlA0);
  SettingsImpl__setInstallationDirectoryPath(command);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Settings__getInstallationDirectoryPath)
{
  const char *path = SettingsImpl__getInstallationDirectoryPath();
  if (path == NULL)
    RML_TAILCALLK(rmlFC);
  else
    rmlA0 = (void*) mk_scon(path);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Settings__setModelicaPath)
{
  const char* command = RML_STRINGDATA(rmlA0);
  SettingsImpl__setModelicaPath(command);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Settings__getModelicaPath)
{
  char *path = SettingsImpl__getModelicaPath(RML_UNTAGFIXNUM(rmlA0));
  if (path == NULL)
    RML_TAILCALLK(rmlFC);
  else
    rmlA0 = mk_scon(path);
  free(path);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Settings__getEcho)
{
  rmlA0  = (void*) mk_icon(echo);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL



RML_BEGIN_LABEL(Settings__setEcho)
{
  echo = (int)RML_UNTAGFIXNUM(rmlA0);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL



RML_BEGIN_LABEL(Settings__dumpSettings)
{
  const char *str;
  if(compileCommand)
    printf("compile command: %s\n",compileCommand);

  if(compilePath)
    printf("Compiler path: %s\n",compilePath);

  if(0 != (str = SettingsImpl__getTempDirectoryPath()))
    printf("temp directory path: %s\n",str);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
