/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

#include <stdio.h>
#include <string.h>

#include "libcsv.h"
#include "omc_file.h"
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

  csvData->handle = omc_fopen(csvData->filename,"w");

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
    unsigned char* newbuffer = (unsigned char*) malloc(dest_size*sizeof(unsigned char));
    dest_size  = csv_write(&newbuffer, dest_size, csvLine, strlen(csvLine));
    fprintf(csvData->handle, "%s", newbuffer);
  }else{
    fprintf(csvData->handle, "%s", buffer);
  }

  return 0;
}
