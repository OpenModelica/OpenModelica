#include "rml.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>

char* compileCommand = 0;
char* tempDirectoryPath = 0;
char* plotCommand = 0;
int echo = 1; //true
void Settings_5finit(void)
{
  
  
}

RML_BEGIN_LABEL(Settings__getVersionNr)
{
    rmlA0 = (void*) mk_scon("1.4.2");
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
  free(omhome);
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
  echo = (int)RML_IMMEDIATE(RML_UNTAGFIXNUM(rmlA0));
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL



RML_BEGIN_LABEL(Settings__dumpSettings)
{
  if(compileCommand) 
    printf("compile command: %s\n",compileCommand);

 
  if(tempDirectoryPath) 
    printf("temp directory path: %s\n",tempDirectoryPath);
 
  if(plotCommand) 
    printf("plot command: %s\n",plotCommand);


  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
