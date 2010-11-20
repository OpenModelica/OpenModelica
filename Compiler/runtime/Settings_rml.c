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

// On windows, set Temp directory path to Temp directory as returned by GetTempPath,
// which is usually TMP or TEMP or windows catalogue.
#ifdef WIN32
	int numChars;
	char* str,str1;
	char tempDirectory[1024];
		//extract the temp path
	numChars= GetTempPath(1024, tempDirectory);
	if (numChars == 1024 || numChars == 0) {
		printf("Error setting temppath in Kernel\n");
	} 
	else {
	 if (tempDirectoryPath) {
		free(tempDirectoryPath);
		tempDirectoryPath=0;
	 }
	 // Must do replacement in two steps, since the _replace function can not have similar source as target.
	 str = _replace(tempDirectory,"\\","/");
	 tempDirectoryPath= _replace(str,"/","\\\\");
	 free(str);
	}
#else
  char* str = NULL;
  str = getenv("TMPDIR");
  if (str == NULL) {
    tempDirectoryPath = malloc(sizeof(char)*(strlen("/tmp") + 1));
    strcpy(tempDirectoryPath, "/tmp");
  }
  else {
    tempDirectoryPath = malloc(sizeof(char)*(strlen(str) + 1));
    strcpy(tempDirectoryPath, str);
  }
#endif
}


RML_BEGIN_LABEL(Settings__getVersionNr)
{
  rmlA0 = (void*) mk_scon(CONFIG_VERSION);
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
  char* command = RML_STRINGDATA(rmlA0);
  if(tempDirectoryPath)
    free(tempDirectoryPath);

  tempDirectoryPath = (char*)malloc(strlen(command)+1);
  if (tempDirectoryPath == NULL) {
    RML_TAILCALLK(rmlFC);
  }
  memcpy(tempDirectoryPath,command,strlen(command)+1);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Settings__getTempDirectoryPath)
{
  if(tempDirectoryPath)
    rmlA0 = (void*) mk_scon(strdup(tempDirectoryPath));
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
  char *path = SettingsImpl__getModelicaPath();
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
  rmlA0	= (void*) mk_icon(echo);
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
  if(compileCommand)
    printf("compile command: %s\n",compileCommand);

  if(compilePath)
    printf("Compiler path: %s\n",compilePath);


  if(tempDirectoryPath)
    printf("temp directory path: %s\n",tempDirectoryPath);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
