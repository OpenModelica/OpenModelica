#ifndef IBPSA_FILEWRITERStructure_c
#define IBPSA_FILEWRITERStructure_c

#include <stdlib.h>
#include <string.h>

#include "ModelicaUtilities.h"

#include "fileWriterStructure.h"

signed int fileWriterIsUnique(const char* fileName){
  int i;
  for(i = 0; i < FileWriterNames_n; i++){
    if (!strcmp(fileName, FileWriterNames[i])){
      return i;
    }
  }
  return -1;
}

void* allocateFileWriter(
  const char* instanceName,
  const char* fileName){
  FileWriter* ID;
  FILE* fp;

  if ( FileWriterNames_n == 0 ){
    /* Allocate memory for array of file names */
    FileWriterNames = (char **)malloc(sizeof(char*));
    InstanceNames = (char **)malloc(sizeof(char*));
    if ( FileWriterNames == NULL || InstanceNames == NULL)
      ModelicaError("Not enough memory in fileWriterStructure.c for allocating FileWriterNames and InstanceNames.");
  }
  else{
    /* Check if the file name is unique */
    signed int index = fileWriterIsUnique(fileName);
    if (index>=0){
      ModelicaFormatError("FileWriter %s writes to file %s which is already used by FileWriter %s.\nEach FileWriter must use a unique file name.",
      instanceName, fileName, InstanceNames[index]);
    }
    /* Reallocate memory for array of file names */
    FileWriterNames = (char **)realloc(FileWriterNames, (FileWriterNames_n+1) * sizeof(char*));
    InstanceNames = (char **)realloc(InstanceNames, (FileWriterNames_n+1) * sizeof(char*));
    if ( FileWriterNames == NULL || InstanceNames == NULL )
      ModelicaError("Not enough memory in fileWriterStructure.c for reallocating FileWriterNames and InstanceNames.");
  }
  /* Allocate memory for this file name */
  FileWriterNames[FileWriterNames_n] = (char *)malloc((strlen(fileName)+1) * sizeof(char));
  InstanceNames[FileWriterNames_n] = (char *)malloc((strlen(instanceName)+1) * sizeof(char));
  if ( FileWriterNames[FileWriterNames_n] == NULL || InstanceNames[FileWriterNames_n] == NULL)
    ModelicaError("Not enough memory in fileWriterStructure.c for allocating FileWriterNames[] and InstanceNames[].");
  /* Copy the file name */
  strcpy(FileWriterNames[FileWriterNames_n], fileName);
  strcpy(InstanceNames[FileWriterNames_n], instanceName);
  FileWriterNames_n++;

  ID = (FileWriter*)malloc(sizeof(*ID));
  if ( ID == NULL )
    ModelicaFormatError("Not enough memory in fileWriterStructure.c for allocating ID of FileWriter %s.", instanceName);

  ID->fileWriterName = (char *)malloc((strlen(fileName)+1) * sizeof(char));
  if ( ID->fileWriterName == NULL )
    ModelicaFormatError("Not enough memory in fileWriterStructure.c for allocating ID->fileWriterName in FileWriter %s.", instanceName);
  strcpy(ID->fileWriterName, fileName);

  ID->instanceName = (char *)malloc((strlen(instanceName)+1) * sizeof(char));
  if ( ID->instanceName == NULL )
    ModelicaFormatError("Not enough memory in fileWriterStructure.c for allocating ID->instanceName in FileWriter %s.", instanceName);
  strcpy(ID->instanceName, instanceName);

  fp = fopen(fileName, "w");
  if (fp == NULL)
    ModelicaFormatError("In fileWriterStructure.c: Failed to create empty file %s during initialisation.", fileName);
  if (fclose(fp)==EOF)
    ModelicaFormatError("In fileWriterStructure.c: Returned an error when closing %s.", fileName);

  return (void*)ID;
}

void freeBase(void* ptrFileWriter){
  FileWriter *ID = (FileWriter*)ptrFileWriter;

  if ( FileWriterNames_n > 0 ){
    FileWriterNames_n--;
    free(FileWriterNames[FileWriterNames_n]);
    free(InstanceNames[FileWriterNames_n]);
    if ( FileWriterNames_n == 0 ){
      free(FileWriterNames);
      free(InstanceNames);
    }
  }
  free(ID->fileWriterName);
  free(ID->instanceName);
  free(ID);
}

#endif
