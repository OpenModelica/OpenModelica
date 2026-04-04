/* Functions that ensures that each FileWriter writes to a unique file
 * and that stores variables in a struct for later use.
 *
 * Michael Wetter, LBNL                     2018-05-12
 * Filip Jorissen, KU Leuven
 */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "ModelicaUtilities.h"

#include "fileWriterStructure.c"

void* fileWriterInit(
  const char* instanceName,
  const char* fileName,
  const int numColumns,
  const int isCombiTimeTable){

  FILE *fp;
  FileWriter* ID = (FileWriter*)allocateFileWriter(instanceName, fileName);

  if (numColumns < 0)
    ModelicaFormatError("In fileWriterInit.c: The number of columns that are written by the FileWriter %s cannot be negative", instanceName);
  ID->numColumns=numColumns;
  ID->numRows=0;

  if (isCombiTimeTable < 0 || isCombiTimeTable > 1)
    ModelicaFormatError("In fileWriterInit.c: The initialisation flag 'isCombiTimeTable' of FileWriter %s must equal 0 or 1 but it equals %i.", instanceName, isCombiTimeTable);
  ID->isCombiTimeTable=isCombiTimeTable;

  fp = fopen(fileName, "w");
  if (fp == NULL)
    ModelicaFormatError("In fileWriterInit.c: Failed to create empty .csv file %s during initialisation.", fileName);
  if (fclose(fp)==EOF)
    ModelicaFormatError("In fileWriterInit.c: Returned an error when closing %s.", fileName);
  return (void*) ID;
}

/* This function writes a line to the FileWriter object file
and counts the total number of lines that are written
by incrementing the counter numRows if isMetaData==0. */
void writeLine(void *ptrFileWriter, const char* line, const int isMetaData){
  FileWriter *ID = (FileWriter*)ptrFileWriter;
  FILE *fOut = fopen(ID->fileWriterName, "a");
  if (fOut == NULL)
    ModelicaFormatError("In fileWriterInit.c: Failed open .csv file %s for appending.", ID->fileWriterName);
  if (fputs(line, fOut)==EOF){
    ModelicaFormatError("In fileWriterInit.c: Returned an error when writing to %s.", ID->fileWriterName);
  }
  if (isMetaData==0)
    ID->numRows=ID->numRows+1;
  if (fclose(fOut)==EOF)
    ModelicaFormatError("In fileWriterInit.c: Returned an error when closing %s.", ID->fileWriterName);
}
