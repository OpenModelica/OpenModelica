#include "rml.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>

char* compileCommand = 0;
char* installationDirectoryPath = 0;
char* tempDirectoryPath = 0;
char* plotCommand = 0;
char* modelicaPath = 0;

void Settings_5finit(void)
{
  
  
}

RML_BEGIN_LABEL(Settings__set_5fcompile_5fcommand)
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

RML_BEGIN_LABEL(Settings__get_5fcompile_5fcommand)
{
  if(compileCommand)
    rmlA0 = (void*) mk_scon(strdup(compileCommand));
  else
    rmlA0 = (void*) mk_scon("");
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Settings__set_5ftemp_5fdirectory_5fpath)
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

RML_BEGIN_LABEL(Settings__get_5ftemp_5fdirectory_5fpath)
{
  if(tempDirectoryPath)
    rmlA0 = (void*) mk_scon(strdup(tempDirectoryPath));
  else
    rmlA0 = (void*) mk_scon("");
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Settings__set_5finstallation_5fdirectory_5fpath)
{
  char* command = RML_STRINGDATA(rmlA0);
  if(installationDirectoryPath)
    free(installationDirectoryPath);

  installationDirectoryPath = (char*)malloc(strlen(command)+1);
  if (installationDirectoryPath == NULL) {
    RML_TAILCALLK(rmlFC);
  }
  memcpy(installationDirectoryPath,command,strlen(command)+1);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Settings__get_5finstallation_5fdirectory_5fpath)
{
  if(installationDirectoryPath)
    rmlA0 = (void*) mk_scon(strdup(installationDirectoryPath));
  else{
    char *path = getenv("OPENMODELICAHOME");
    if (path == NULL) {
      rmlA0 = (void*) mk_scon("");
      RML_TAILCALLK(rmlFC);
    }
    else
      rmlA0 = (void*) mk_scon(path);
  }
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Settings__set_5fplot_5fcommand)
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

RML_BEGIN_LABEL(Settings__get_5fplot_5fcommand)
{
  if(plotCommand)
    rmlA0 = (void*) mk_scon(strdup(plotCommand));
  else
    rmlA0 = (void*) mk_scon("");
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Settings__set_5fmodelica_5fpath)
{
  char* command = RML_STRINGDATA(rmlA0);
  if(modelicaPath)
    free(modelicaPath);

  modelicaPath = (char*)malloc(strlen(command)+1);
  if (modelicaPath == NULL) {
    RML_TAILCALLK(rmlFC);
  }
  memcpy(modelicaPath,command,strlen(command)+1);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Settings__get_5fmodelica_5fpath)
{
  if(modelicaPath)
    rmlA0 = (void*) mk_scon(strdup(modelicaPath));
  else{
    char *path = getenv("MODELICAPATH");
    if (path == NULL) {
      rmlA0 = (void*) mk_scon("");
      RML_TAILCALLK(rmlFC);
    }
    else
      rmlA0 = (void*) mk_scon(path);
  }
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Settings__dump_5fsettings)
{
  if(compileCommand) 
    printf("compile command: %s\n",compileCommand);

  if(installationDirectoryPath) 
    printf("installation directory path: %s\n",installationDirectoryPath);
 
  if(tempDirectoryPath) 
    printf("temp directory path: %s\n",tempDirectoryPath);
 
  if(plotCommand) 
    printf("plot command: %s\n",plotCommand);

  if(modelicaPath) 
    printf("modelica path: %s\n",modelicaPath);


  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
