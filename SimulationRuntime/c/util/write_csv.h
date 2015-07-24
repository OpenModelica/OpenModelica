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

#ifndef OMC_WRITE_CSV_H
#define OMC_WRITE_CSV_H

#include <stdio.h>
#include <string.h>

typedef struct omc_write_csv {
  char* filename;
  FILE* handle;
  char seperator;
  char quote;
} OMC_WRITE_CSV;

struct csvStats {
  OMC_WRITE_CSV* callStats;
  OMC_WRITE_CSV* iterStats;
};

#ifdef __cplusplus
extern "C" {
#endif

OMC_WRITE_CSV*
omc_write_csv_init(char filename[], char seperator, char quote);
int omc_write_csv_free(OMC_WRITE_CSV* csvData);
int omc_write_csv(OMC_WRITE_CSV* csvData, const void* csvLine);

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif
