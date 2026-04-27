/* Function that frees the memory for the FileWriter.
 *
 * Michael Wetter, LBNL                     2018-05-12
 */

#ifndef IBPSA_FILEWRITERFree_c
#define IBPSA_FILEWRITERFree_c

#include <stdlib.h>
#include <stdio.h>
#include "ModelicaUtilities.h"

#include "fileWriterStructure.h"

void prependString(const char* fileName, const char* string){
  char *origString;
  FILE *fOut;
  long fsize;
  /* read original file contents */
  FILE *fr = fopen(fileName, "r");
  if(fseek(fr, 0, SEEK_END)!=0)
    ModelicaFormatError("The file %s could not be read.", fileName);
  fsize = ftell(fr);
  if (fsize==-1)
    ModelicaFormatError("The file %s could not be read.", fileName);
  if(fseek(fr, 0, SEEK_SET)!=0)
    ModelicaFormatError("The file %s could not be read.", fileName);

  origString = (char *)malloc((fsize + 1) * sizeof(char));
  if ( origString == NULL ){
    /* not enough memory is available: file too large */
    ModelicaError("Not enough memory in fileWriterInit.c for prepending string.");
  }
  if (fread(origString, fsize, 1, fr)==0)
    ModelicaFormatError("The file %s could not be read.", fileName);

  fclose(fr);
  origString[fsize] = '\0';

  /* write new contents */
  fOut = fopen(fileName, "w");
  /* prepended string */
  if (fputs(string, fOut)==EOF)
    ModelicaFormatError("The file %s could not be written.", fileName);
  /* original data */
  if (fputs(origString, fOut)==EOF)
    ModelicaFormatError("The file %s could not be written.", fileName);

  fclose(fOut);

  free(origString);
}

void fileWriterFree(void* ptrFileWriter){
  FileWriter *ID = (FileWriter*)ptrFileWriter;

  /* If this FileWriter writes in a CombiTimeTable format, prepend the required header
  now that we know how many lines have been written. */
  if (ID->isCombiTimeTable){
    char buf[255];
    sprintf(buf,"#1\ndouble csv(%i,%i)\n",ID->numRows,ID->numColumns);
    prependString(ID->fileWriterName, buf);
  }

  freeBase(ptrFileWriter);

  return;
}

#endif
