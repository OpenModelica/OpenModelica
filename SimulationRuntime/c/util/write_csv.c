/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include <stdio.h>
#include <string.h>

#include "libcsv.h"
#include "write_csv.h"

#define CSV_BUFFER_SIZE 1024

OMC_WRITE_CSV* omc_write_csv_init(char filename[], char seperator, char quote){
  int i;
  size_t n = strlen(filename);

  OMC_WRITE_CSV* csvData = (OMC_WRITE_CSV*) malloc(sizeof(OMC_WRITE_CSV));
  csvData->filename = (char*) malloc((n+1)*sizeof(char));

  strncpy(csvData->filename, filename, n);
  csvData->filename[n] = '\0';
  csvData->seperator = seperator;
  csvData->quote = '"';

  csvData->handle = fopen(csvData->filename,"w");

  return csvData;
}


int omc_write_csv_free(OMC_WRITE_CSV* csvData){

  int i;

  free(csvData->filename);
  fclose(csvData->handle);

  return 0;
}

int omc_write_csv(OMC_WRITE_CSV* csvData, const void* csvLine){

  size_t dest_size;
  unsigned char buffer[CSV_BUFFER_SIZE] = "";

  dest_size  = csv_write(&buffer, CSV_BUFFER_SIZE, csvLine, strlen(csvLine));
  if (dest_size > CSV_BUFFER_SIZE){
    unsigned char* newbuffer = (unsigned char*) malloc(dest_size*sizeof(char));
    dest_size  = csv_write(&newbuffer, dest_size, csvLine, strlen(csvLine));
    fprintf(csvData->handle, "%s", newbuffer);
  }else{
    fprintf(csvData->handle, "%s", buffer);
  }

  return 0;
}
