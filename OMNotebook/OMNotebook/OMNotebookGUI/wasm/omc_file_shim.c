/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*
 * Minimal stdio implementation of the four omc_file functions the OMPlot result
 * readers (read_matlab4.c / read_csv.c) use, so they can be compiled for the web
 * build without the simulation runtime (omc_file.c pulls in the MetaModelica
 * runtime via omc_error.h). omc_strdup and omc_fseek are header-only.
 */
#include <stdio.h>

FILE* omc_fopen(const char *filename, const char *mode)
{
  return fopen(filename, mode);
}

int omc_fclose(FILE *stream)
{
  return fclose(stream);
}

size_t omc_fread(void *buffer, size_t size, size_t count, FILE *stream, int allow_early_eof)
{
  (void) allow_early_eof;
  return fread(buffer, size, count, stream);
}

size_t omc_fwrite(void *buffer, size_t size, size_t count, FILE *stream)
{
  return fwrite(buffer, size, count, stream);
}
