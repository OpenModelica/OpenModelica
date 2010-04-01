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


#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* malloc.h is in sys in Mac OS */
#ifdef __APPLE_CC__
#include <sys/malloc.h>
#else /* Linux or Windows here */
#include <malloc.h>
#endif

#include "rml.h"

#ifdef WIN32
#include <Windows.h>
#endif

char* compileCommand = 0;
char* compilePath = 0;
char* tempDirectoryPath = 0;
char* plotCommand = 0;

int echo = 1; //true

char* _replace(char* source_str,char* search_str,char* replace_str); //Defined in systemimpl.c

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
  /* adrpo: TODO! FIXME!
   * MathCore wants this set to g++
   * but OpenModelica uses $OPENMODELICAHOME/bin/Compile
   * now this is solved in CevalScript.compileModel which is different for OpenModelica vs. MathModelica
   */
  str = NULL;
  str = getenv("MC_DEFAULT_COMPILE_CMD");
  if (str == NULL) {
    compileCommand = malloc(sizeof(char)*(strlen("g++") + 1));
    strcpy(compileCommand,"g++");
  } else {
    compileCommand = malloc(sizeof(char)*(strlen(str) + 1));
    strcpy(compileCommand, str);
  }
  str = NULL;
  str = getenv("MC_DEFAULT_COMPILE_PATH");
  if (str != NULL) {
	  compilePath = malloc(sizeof(char)*(strlen(str) + 1));
	  strcpy(compilePath, str);
  }
}


RML_BEGIN_LABEL(Settings__getVersionNr)
{
    rmlA0 = (void*) mk_scon("1.5.0");
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
  if(compileCommand)
    rmlA0 = (void*) mk_scon(strdup(compileCommand));
  else
    rmlA0 = (void*) mk_scon("");
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
  if(compilePath)
    rmlA0 = (void*) mk_scon(strdup(compilePath));
  else
    rmlA0 = (void*) mk_scon("");
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
  char* command = RML_STRINGDATA(rmlA0);
  char* omhome = 0;
  char* installationDirectoryPath = NULL;

  installationDirectoryPath = (char*)malloc(strlen(command)+1);
  if (installationDirectoryPath == NULL) {
    RML_TAILCALLK(rmlFC);
  }
  memcpy(installationDirectoryPath,command,strlen(command)+1);

  /* create a str of the form: OPENMODELICAHOME=<PATH>*/
  omhome = (char*)malloc(strlen(command)+1+18);
  if (omhome == NULL) {
    RML_TAILCALLK(rmlFC);
  }
  strncpy(omhome,"OPENMODELICAHOME=",17);
  omhome[17]='\0';
  strncat(omhome,command,strlen(command));
  /*set the env-var to created string
   this is useful when scripts and clients started
  by omc wants to use OPENMODELICAHOME*/
    if( putenv(omhome) != 0) // adrpo: in Linux there is not _putenv if( _putenv(omhome) != 0)
  {
    RML_TAILCALLK(rmlFC);
  }
#if defined(WIN32)
  /* Only free on windows, in Linux the environment is taking over the ownership of the ptr */
  free(omhome);
#endif
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Settings__getInstallationDirectoryPath)
{

    char *path = getenv("OPENMODELICAHOME");
    if (path == NULL) {
      rmlA0 = (void*) mk_scon("");
      RML_TAILCALLK(rmlFC);
    }
    else
      rmlA0 = (void*) mk_scon(path);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Settings__setPlotCommand)
{
  char* command = RML_STRINGDATA(rmlA0);
  if(plotCommand)
    free(plotCommand);

  plotCommand = (char*)malloc(strlen(command)+1);
  if (plotCommand == NULL) {
    RML_TAILCALLK(rmlFC);
  }
  memcpy(plotCommand,command,strlen(command)+1);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Settings__getPlotCommand)
{
  if(plotCommand)
    rmlA0 = (void*) mk_scon(strdup(plotCommand));
  else
    rmlA0 = (void*) mk_scon("");
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Settings__setModelicaPath)
{
  char* command = RML_STRINGDATA(rmlA0);
  char* mmpath;
  char* modelicaPath = NULL;

  modelicaPath = (char*)malloc(strlen(command)+1);
  if (modelicaPath == NULL) {
    RML_TAILCALLK(rmlFC);
  }
  memcpy(modelicaPath,command,strlen(command)+1);

 /* create a str of the form: OPENMODELICALIBRARY=<PATH>*/
  mmpath = (char*)malloc(strlen(command)+1+strlen("OPENMODELICALIBRARY="));
  if (mmpath == NULL) {
    RML_TAILCALLK(rmlFC);
  }
  strncpy(mmpath,"OPENMODELICALIBRARY=",strlen("OPENMODELICALIBRARY="));
  mmpath[strlen("OPENMODELICALIBRARY=")]='\0';
  strncat(mmpath,command,strlen(command));
  /*set the env-var to created string
   this is useful when scripts and clients started
  by omc wants to use OPENMODELICAHOME*/
    if( putenv(mmpath) != 0) // adrpo: in Linux there is not _putenv if( _putenv(omhome) != 0)
  {
    RML_TAILCALLK(rmlFC);
  }

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Settings__getModelicaPath)
{

	 char *path = getenv("OPENMODELICALIBRARY");
	 if (path == NULL) {
	    rmlA0 = (void*) mk_scon("");
	    RML_TAILCALLK(rmlFC);
	  }
	  else
	    rmlA0 = (void*) mk_scon(path);
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

  if(plotCommand)
    printf("plot command: %s\n",plotCommand);


  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
